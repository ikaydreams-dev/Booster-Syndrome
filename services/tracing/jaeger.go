package tracing

import (
	"context"
	"io"
	"log"

	"github.com/opentracing/opentracing-go"
	"github.com/opentracing/opentracing-go/ext"
	"github.com/uber/jaeger-client-go"
	"github.com/uber/jaeger-client-go/config"
)

type Tracer struct {
	tracer opentracing.Tracer
	closer io.Closer
}

func NewTracer(serviceName string) (*Tracer, error) {
	cfg := config.Configuration{
		ServiceName: serviceName,
		Sampler: &config.SamplerConfig{
			Type:  jaeger.SamplerTypeConst,
			Param: 1,
		},
		Reporter: &config.ReporterConfig{
			LogSpans:           true,
			LocalAgentHostPort: "localhost:6831",
		},
	}

	tracer, closer, err := cfg.NewTracer()
	if err != nil {
		return nil, err
	}

	opentracing.SetGlobalTracer(tracer)

	return &Tracer{
		tracer: tracer,
		closer: closer,
	}, nil
}

func (t *Tracer) Close() {
	if t.closer != nil {
		t.closer.Close()
	}
}

func StartSpan(ctx context.Context, operationName string) (opentracing.Span, context.Context) {
	var span opentracing.Span

	if parentSpan := opentracing.SpanFromContext(ctx); parentSpan != nil {
		span = opentracing.StartSpan(
			operationName,
			opentracing.ChildOf(parentSpan.Context()),
		)
	} else {
		span = opentracing.StartSpan(operationName)
	}

	return span, opentracing.ContextWithSpan(ctx, span)
}

func StartHTTPSpan(ctx context.Context, method, url string) (opentracing.Span, context.Context) {
	span, ctx := StartSpan(ctx, method+" "+url)

	ext.HTTPMethod.Set(span, method)
	ext.HTTPUrl.Set(span, url)
	ext.SpanKindRPCClient.Set(span)

	return span, ctx
}

func StartDBSpan(ctx context.Context, operation, table string) (opentracing.Span, context.Context) {
	span, ctx := StartSpan(ctx, operation+" "+table)

	ext.DBType.Set(span, "sql")
	ext.DBStatement.Set(span, operation)
	ext.DBInstance.Set(span, table)

	return span, ctx
}

func LogError(span opentracing.Span, err error) {
	if err != nil {
		ext.Error.Set(span, true)
		span.LogKV("error", err.Error())
	}
}

func SetTag(span opentracing.Span, key string, value interface{}) {
	span.SetTag(key, value)
}

func InjectSpanContext(span opentracing.Span) map[string]string {
	headers := make(map[string]string)

	err := opentracing.GlobalTracer().Inject(
		span.Context(),
		opentracing.TextMap,
		opentracing.TextMapCarrier(headers),
	)

	if err != nil {
		log.Printf("Failed to inject span context: %v", err)
	}

	return headers
}

func ExtractSpanContext(headers map[string]string) (opentracing.SpanContext, error) {
	return opentracing.GlobalTracer().Extract(
		opentracing.TextMap,
		opentracing.TextMapCarrier(headers),
	)
}
