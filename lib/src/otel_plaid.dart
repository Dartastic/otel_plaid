// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_plaid_suppression.dart';

const _tracerName = 'dartastic_otel_libs_plaid';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any Plaid v2 API call in a CLIENT span. [endpoint] is
/// the dotted Plaid endpoint (e.g. `transactions/get`,
/// `auth/get`, `link/token/create`).
Future<T> tracedPlaid<T>({
  required String endpoint,
  required Future<T> Function() invoke,
  String? environment,
  String? institutionId,
  String? itemId,
}) async {
  if (plaidInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'plaid.endpoint': endpoint,
    'plaid.operation': endpoint.replaceAll('/', '.'),
  };
  if (environment != null) m['plaid.environment'] = environment;
  if (institutionId != null) m['plaid.institution.id'] = institutionId;
  if (itemId != null) m['plaid.item.id'] = itemId;

  final span = _tracer().startSpan(
    'plaid $endpoint',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
