# 🩺 Nurse AI: A Lightweight Runtime Integrity Layer for LLMs

This repository introduces **Nurse AI**, a proof-of-concept framework for monitoring and correcting large language model (LLM) output in real-time. The goal is to detect drift, hallucination, and instability—then intervene gently without impairing fluency.

---

## 📄 Contents

| File | Description |
|------|-------------|
| `NurseAI.pdf` | White paper describing the motivation, architecture, and tiered integrity framework |
| `NurseAIDemo.R` | R implementation of a runtime diagnostic and scoring script |
| `NurseAIDemo.py` | Python implementation of the same logic for cross-platform compatibility |
| `README.md` | This file |

---

## 🚑 What Is Nurse AI?

Nurse AI acts as a **companion agent** that evaluates each LLM output in real-time. It:

- Scores outputs on **topic drift** and **volatility**
- Flags potential hallucinations
- Recommends soft interventions (e.g., rewording prompts, warning users)
- Escalates to stronger safeguards if needed

> “It’s not a jailer—it’s a nurse.”

---

## 🚀 Quick Start

### Python Version

```bash
python NurseAIDemo.py
