// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_plaid/otel_plaid.dart';

/// Traces Plaid calls with OpenTelemetry.
///
/// `otel_plaid` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Plaid call in
/// [tracedPlaid]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'plaid-example');

  // Wraps any Plaid v2 API call in a CLIENT span.
  final plaidId = await tracedPlaid<String>(
    endpoint: 'example',
    environment: 'example',
    institutionId: 'institution_8f3a2c',
    itemId: 'item_8f3a2c',
    invoke: () async {
      // Make the Plaid call here, then report what it returned.
      return 'plaid_8f3a2c';
    },
  );
  OTelLog.info('tracedPlaid link/token/create returned $plaidId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPlaidInstrumentationAsync.
  await runWithoutPlaidInstrumentationAsync(
    () => tracedPlaid<String>(
      endpoint: 'example',
      environment: 'example',
      institutionId: 'institution_8f3a2c',
      itemId: 'item_8f3a2c',
      invoke: () async {
        return 'plaid_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
