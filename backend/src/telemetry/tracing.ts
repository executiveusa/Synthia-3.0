import { env } from '../config/env.js';
import { diag, DiagConsoleLogger, DiagLogLevel } from '@opentelemetry/api';
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

let sdk: NodeSDK | undefined;

diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.ERROR);

export function initTracing() {
  if (sdk) {
    return sdk;
  }

  if (env.NODE_ENV === 'test') {
    return undefined;
  }

  const exporter = env.OTLP_ENDPOINT
    ? new OTLPTraceExporter({ url: env.OTLP_ENDPOINT })
    : undefined;

  sdk = new NodeSDK({
    traceExporter: exporter,
    resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: 'synthia-backend',
      [SemanticResourceAttributes.CLOUD_PROVIDER]: env.GOOGLE_PROJECT_ID ? 'gcp' : 'local'
    })
  });

  Promise.resolve(sdk.start()).catch((error) => {
    console.error('Failed to start telemetry SDK', error);
  });

  return sdk;
}

export async function shutdownTracing() {
  if (!sdk) return;
  await sdk.shutdown();
  sdk = undefined;
}
