// Security-rule tests against the Firestore emulator. Run: npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp, writeBatch, collection,
} from 'firebase/firestore';

let env;
const campus = (uid, verified = true) => ({ email: `${uid}@alustudent.com`, email_verified: verified });

const db = (uid, token = campus(uid)) => env.authenticatedContext(uid, token).firestore();

const report = (uid, extra = {}) => ({
  title: 'Leaking tap', description: 'Water leaking under the sink.', category: 'water',
  location: 'Library', status: 'submitted', priority: 'medium', reporterId: uid,
  reporterName: 'Amina', isAnonymous: false, isHidden: false, photoUrl: null,
  resolutionNote: null, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-campusfix',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'users/staff'), { name: 'Staff', role: 'staff' });
    await setDoc(doc(f, 'users/amina'), { name: 'Amina', role: 'student' });
    await setDoc(doc(f, 'incidents/i1'), report('amina', { createdAt: new Date(), updatedAt: new Date() }));
  });
});

// ------------------------------------------------------------- users

test('student registers only as student with a campus email', async () => {
  await assertSucceeds(setDoc(doc(db('new'), 'users/new'), { name: 'N', role: 'student' }));
  await assertFails(setDoc(doc(db('evil'), 'users/evil'), { name: 'E', role: 'staff' }));
  const gmail = env.authenticatedContext('g', { email: 'g@gmail.com', email_verified: true }).firestore();
  await assertFails(setDoc(doc(gmail, 'users/g'), { name: 'G', role: 'student' }));
});

test('nobody can promote themselves', async () => {
  await assertFails(updateDoc(doc(db('amina'), 'users/amina'), { role: 'staff' }));
  await assertSucceeds(updateDoc(doc(db('amina'), 'users/amina'), { department: 'CS' }));
});

test("students can't read other users; staff can", async () => {
  await assertFails(getDoc(doc(db('amina'), 'users/staff')));
  await assertSucceeds(getDoc(doc(db('staff'), 'users/amina')));
});

// ------------------------------------------------------------- incidents

test('unverified or signed-out users cannot read reports', async () => {
  await assertFails(getDoc(doc(db('amina', campus('amina', false)), 'incidents/i1')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'incidents/i1')));
  await assertSucceeds(getDoc(doc(db('amina'), 'incidents/i1')));
});

test('student creates own submitted report (with first history entry)', async () => {
  const f = db('amina');
  const ref = doc(collection(f, 'incidents'));
  const batch = writeBatch(f);
  batch.set(ref, report('amina'));
  batch.set(doc(collection(ref, 'history')), { from: null, to: 'submitted', byName: 'Amina', note: null, at: serverTimestamp() });
  await assertSucceeds(batch.commit());
});

test('create rejects spoofed reporter, pre-set status, bad lengths, extra fields', async () => {
  const f = db('amina');
  await assertFails(setDoc(doc(f, 'incidents/x1'), report('someone-else')));
  await assertFails(setDoc(doc(f, 'incidents/x2'), report('amina', { status: 'resolved' })));
  await assertFails(setDoc(doc(f, 'incidents/x3'), report('amina', { title: 'ab' })));
  await assertFails(setDoc(doc(f, 'incidents/x4'), report('amina', { isHidden: true })));
  await assertFails(setDoc(doc(f, 'incidents/x5'), report('amina', { role: 'staff' })));
});

test('student cannot change workflow fields', async () => {
  const f = db('amina');
  await assertFails(updateDoc(doc(f, 'incidents/i1'), { status: 'resolved' }));
  await assertFails(updateDoc(doc(f, 'incidents/i1'), { priority: 'high' }));
  await assertFails(updateDoc(doc(db('other'), 'incidents/i1'), { title: 'Hijacked title' }));
});

test('owner edits/deletes only while submitted', async () => {
  await assertSucceeds(updateDoc(doc(db('amina'), 'incidents/i1'), { title: 'Leaking tap, room 2' }));
  await env.withSecurityRulesDisabled((ctx) =>
    updateDoc(doc(ctx.firestore(), 'incidents/i1'), { status: 'inProgress' }));
  await assertFails(updateDoc(doc(db('amina'), 'incidents/i1'), { title: 'Changed later' }));
  await assertFails(deleteDoc(doc(db('amina'), 'incidents/i1')));
});

test('staff changes status + history + notification in one batch', async () => {
  const f = db('staff');
  const batch = writeBatch(f);
  batch.update(doc(f, 'incidents/i1'), { status: 'inReview', resolutionNote: null, updatedAt: serverTimestamp() });
  batch.set(doc(collection(f, 'incidents/i1/history')), { from: 'submitted', to: 'inReview', byName: 'Staff', note: null, at: serverTimestamp() });
  batch.set(doc(collection(f, 'users/amina/notifications')), { incidentId: 'i1', title: 't', message: 'm', read: false, at: serverTimestamp() });
  await assertSucceeds(batch.commit());
});

test('staff cannot rewrite report content', async () => {
  await assertFails(updateDoc(doc(db('staff'), 'incidents/i1'), { description: 'Rewritten by staff member' }));
});

// ------------------------------------------------------------- notifications

test('notifications: only owner reads/marks read, only staff creates', async () => {
  await assertFails(setDoc(doc(db('amina'), 'users/amina/notifications/n1'), { read: false }));
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'users/amina/notifications/n1'), { title: 't', read: false }));
  await assertSucceeds(updateDoc(doc(db('amina'), 'users/amina/notifications/n1'), { read: true }));
  await assertFails(updateDoc(doc(db('amina'), 'users/amina/notifications/n1'), { title: 'x' }));
  await assertFails(getDoc(doc(db('other'), 'users/amina/notifications/n1')));
});
