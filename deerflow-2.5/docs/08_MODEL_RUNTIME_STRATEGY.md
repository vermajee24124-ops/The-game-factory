# DeerFlow 2.5 — Model Runtime Strategy

## Principle

The model is an interchangeable runtime dependency. DeerFlow 2.5 must not hard-code a single vendor or model into its research architecture.

## Low-cost local profile

For a T4-class deployment, use an open-weight reasoning model in a quantized form that fits available VRAM. The model should support tool calling and, when available, native thinking/reasoning mode.

A practical starting profile is a Qwen3-family thinking model at a quantization selected by the operator. Model selection must be benchmarked on the actual DeerFlow research mission rather than chosen only by parameter count.

## Routing roles

A deployment may assign separate models for:

- research planning
- research workers
- result compression
- final synthesis
- vision/document tasks

A single model is acceptable for a simple installation. A model router can be introduced later without changing the research contract.

## Cloud fallback

Cloud APIs may be configured as optional fallback providers. They do not become part of the open-source baseline and their quotas/pricing remain provider-specific.

## No unlimited claim

The project must never describe any hosted model as unlimited unless the provider's current contract explicitly guarantees that property. Local inference is limited by the user's own compute and operational capacity.
