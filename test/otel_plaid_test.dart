// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_plaid/otel_plaid.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_plaid-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('transactions/get records CLIENT span', () async {
    await tracedPlaid<String>(
      endpoint: 'transactions/get',
      environment: 'sandbox',
      itemId: 'item-1',
      invoke: () async => 'txns',
    );
    final a = attrsOf(spans.findSpanByName('plaid transactions/get')!);
    expect(a['plaid.endpoint'], 'transactions/get');
    expect(a['plaid.operation'], 'transactions.get');
    expect(a['plaid.environment'], 'sandbox');
    expect(a['plaid.item.id'], 'item-1');
  });

  test('records exception', () async {
    await expectLater(
      tracedPlaid<String>(
        endpoint: 'auth/get',
        invoke: () async => throw StateError('boom'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      spans.findSpanByName('plaid auth/get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutPlaidInstrumentationAsync(() async {
      await tracedPlaid<String>(
        endpoint: 'auth/get',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('plaid '), isEmpty);
  });
}
