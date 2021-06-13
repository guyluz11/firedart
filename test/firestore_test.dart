import 'dart:convert';

import 'package:firebase_auth_rest/firebase_auth_rest.dart';
import 'package:firedart/firedart.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'test_config.dart';

Future main() async {
  var tokenStore = VolatileStore();
  var client = Client();

  var auth = FirebaseAuth(client, apiKey);
  var firestore = Firestore(projectId, auth: auth);
  await auth.signInWithPassword(email, password);

  test('Create reference', () async {
    // Ensure document exists
    var reference = firestore.document('test/reference');
    await reference.set({'field': 'test'});

    var collectionReference = firestore.reference('test');
    expect(collectionReference.runtimeType, equals(CollectionReference));
    var documentReference = firestore.reference('test/types');
    expect(documentReference.runtimeType, equals(DocumentReference));

    await reference.delete();
  });

  test('Get collection', () async {
    var reference = firestore.collection('test');
    var documents = await reference.get();
    expect(documents.isNotEmpty, true);
  });

  test('Limit collection page size', () async {
    var reference = firestore.collection('test');
    var documents = await reference.get(pageSize: 1);
    expect(documents.length, 1);
    expect(documents.hasNextPage, isTrue);
  });

  test('Get next collection page', () async {
    var reference = firestore.collection('test');
    var documents = await reference.get(pageSize: 1);
    var first = documents[0];
    documents = await reference.get(
        pageSize: 1, nextPageToken: documents.nextPageToken);
    var second = documents[0];
    expect(first.id, isNot(second.id));
  });

  test('Simple query', () async {
    await firestore.document('test/query').set({'test_field': 'test_value'});
    var query = await firestore
        .collection('test')
        .where('test_field', isEqualTo: 'test_value')
        .get();
    expect(query.isNotEmpty, true);
  });

  test('Multiple query parameters', () async {
    await firestore.document('test/query').set({'test_field': 42});
    var query = await firestore
        .collection('test')
        .where('test_field', isEqualTo: 42, isGreaterThan: 41, isLessThan: 43)
        .get();
    expect(query.isNotEmpty, true);
  });

  test('Add and delete collection document', () async {
    var reference = firestore.collection('test');
    var docReference = await reference.add({'field': 'test'});
    expect(docReference['field'], 'test');
    var document = reference.document(docReference.id);
    expect(await document.exists, true);
    await document.delete();
    expect(await document.exists, false);
  });

  test('Add and delete named document', () async {
    var reference = firestore.document('test/add_remove');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Path with leading slash', () async {
    var reference = firestore.document('/test/path');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Path with trailing slash', () async {
    var reference = firestore.document('test/path/');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Path with leading and trailing slashes', () async {
    var reference = firestore.document('/test/path/');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Read data from document', () async {
    var reference = firestore.collection('test').document('read_data');
    await reference.set({'field': 'test'});
    var map = await reference.get();
    expect(map['field'], 'test');
    await reference.delete();
  });

  test('Overwrite document', () async {
    var reference = firestore.collection('test').document('overwrite');
    await reference.set({'field1': 'test1', 'field2': 'test1'});
    await reference.set({'field1': 'test2'});
    var doc = await reference.get();
    expect(doc['field1'], 'test2');
    expect(doc['field2'], null);
    await reference.delete();
  });

  test('Update document', () async {
    var reference = firestore.collection('test').document('update');
    await reference.set({'field1': 'test1', 'field2': 'test1'});
    await reference.update({'field1': 'test2'});
    var doc = await reference.get();
    expect(doc['field1'], 'test2');
    expect(doc['field2'], 'test1');
    await reference.delete();
  });

  // test('Stream document changes', () async {
  //   var reference = firestore.document('test/subscribe');
  //
  //   // Firestore may send empty events on subscription because we're reusing the
  //   // document path.
  //   expect(reference.stream.where((doc) => doc != null),
  //       emits((document) => document['field'] == 'test'));
  //
  //   await reference.set({'field': 'test'});
  //   await reference.delete();
  // });

  test('Stream collection changes', () async {
    var reference = firestore.collection('test');

    var document = await reference.add({'field': 'test'});
    expect(reference.stream,
        emits((List<Document> documents) => documents.isNotEmpty));
    await document.reference.delete();
  });

  test('Document field types', () async {
    var reference = firestore.collection('test').document('types');
    var dateTime = DateTime.now();
    var geoPoint = GeoPoint(38.7223, 9.1393);
    await reference.set({
      'null': null,
      'bool': true,
      'int': 1,
      'double': 0.1,
      'timestamp': dateTime,
      'bytes': utf8.encode('byte array'),
      'string': 'text',
      'reference': reference,
      'coordinates': geoPoint,
      'list': [1, 'text'],
      'map': {'int': 1, 'string': 'text'},
    });
    var doc = await reference.get();
    expect(doc['null'], null);
    expect(doc['bool'], true);
    expect(doc['int'], 1);
    expect(doc['double'], 0.1);
    expect(doc['timestamp'], dateTime);
    expect(doc['bytes'], utf8.encode('byte array'));
    expect(doc['string'], 'text');
    expect(doc['reference'], reference);
    expect(doc['coordinates'], geoPoint);
    expect(doc['list'], [1, 'text']);
    expect(doc['map'], {'int': 1, 'string': 'text'});
  });
}
