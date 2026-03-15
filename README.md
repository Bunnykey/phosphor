# Phosphor

Real-time ML visualization dashboard built with Phoenix LiveView and the Nx ecosystem.

**Live demo:** https://phosphor.dailymicrotools.com

## Features

- **Anomaly Detection** — Stream sensor data through an Axon autoencoder and flag outliers in real time. Five data sources (sine wave, ECG, network traffic, crypto, system metrics) with adjustable window size and threshold.
- **Image Classification** — Upload an image and get top-5 predictions from a ResNet-50 model served via Bumblebee.
- **Sentiment Analysis** — Analyze text sentiment using a multilingual mBERT model. Supports English, Korean, German, French, Spanish, and Italian.
- **Training Visualization** — Watch loss and accuracy curves update live during Axon training runs. Choose between MNIST, Fashion-MNIST, and XOR datasets with configurable hyperparameters.

## Tech Stack

- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) — real-time UI over WebSocket
- [Nx](https://hexdocs.pm/nx) + [EXLA](https://hexdocs.pm/exla) — numerical computing
- [Axon](https://hexdocs.pm/axon) + [Polaris](https://hexdocs.pm/polaris) — neural networks and optimizers
- [Bumblebee](https://hexdocs.pm/bumblebee) — pre-trained model serving (ResNet-50, mBERT)
- [Chart.js](https://www.chartjs.org/) — client-side charts via LiveView hooks

## Getting Started

```bash
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000).

### Requirements

- Elixir 1.15+
- Erlang/OTP 26+
- Node.js (for asset compilation)

Models are downloaded from HuggingFace on first startup. The app starts normally even without network access and retries model loading in the background.

## Running Tests

```bash
# Elixir tests
mix test

# JavaScript tests
cd assets && npx vitest run
```

## License

MIT
