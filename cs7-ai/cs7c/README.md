# ASB Case Study 7C – Building a RAG and AI Agent with ShopEase Philippines Data

This project implements a [case study from the Analytics Solutions Bootcamp (Josh Dev PH)](https://github.com/imjbmkz/analytics-solutions-bootcamp/blob/main/03_case_study/07_cs03_artificial_intelligence.md) of building a Retrieval-Augmented Generation (RAG) and AI Agent for a fictional omnichannel retail company.

## Situation

ShopEase Philippines is a fictional omnichannel retail company that manages customer orders, products, stores, inventory, support tickets, promotions, and company policies.

The company has information stored across different file formats and data sources. Employees often need to combine information from several of these sources to answer customer questions.

For example, a customer may ask:

> "My order arrived damaged. Can I still return it, and is a replacement available?"

Answering this question may require information from:

- the customer's order,
- the product catalog,
- the return and refund policy,
- current store inventory, and
- possibly an existing support ticket

Our task is to build a simple Retrieval-Augmented Generation (RAG) application and a simple AI Agent using the provided ShopEase dataset.

This is not intended to be a production-grade AI engineering project. The objective is to experience how RAG and Agents work and understand the difference between retrieving knowledge and allowing an AI system to choose and use tools.

## Setup

1. Fork the repository then clone locally on your machine.
2. [Download and install uv](https://docs.astral.sh/uv/#installation)
3. [Download and install Ollama](https://ollama.com/download/)
4. While in the working directory, follow the following commands:

```bash
# Create virtual environment
uv venv --python 3.13

# Sync virtual environment to install dependencies
uv sync --group dev

# Do this if no existing Jupyter environment in the system
uv add --dev jupyter

# Create a kernel for this project
uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --name=asb-ai

# Launch Jupyter Lab and use the created kernel in the notebook
uv run jupyter lab
```

5. Start Ollama

```bash
ollama serve
```

6. Download the required models

```bash
ollama pull nomic-embed-text
ollama pull llama3.2
```

7. Optional: Run the cells in `test_query.ipynb` to test if models are running properly.
