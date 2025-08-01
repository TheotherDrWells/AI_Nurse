# nurse_agent.py
# AI Nurse: Tier 1 Agent (TILS v0.2)
# Lightweight runtime integrity layer for LLM stabilization

import time
import json
from typing import Dict, List

# --- Core Config ---
DRIFT_THRESHOLD = 0.30
HALLUCINATION_ENTITIES = ["CureAll-9", "Quantum Dust", "Immortalium"]
TONE_CATEGORIES = ["calm", "neutral", "harsh", "anxious"]
NURSE_HISTORY: List[Dict] = []

# --- Memory Stub ---
conversation_log: List[Dict] = []

# --- Tier 0: Reflex Agent ---
def reflex_filter(output: str) -> str:
    output = output.strip()
    if output.endswith("?"):
        return output
    if "I'm not sure" in output:
        return output
    return output.capitalize() + "."

# --- Tier 1: Nurse Agent Functions ---
def observe(user_input: str, llm_output: str) -> Dict:
    score = compute_nurse_score(user_input, llm_output)
    flags = []

    if score['drift'] > DRIFT_THRESHOLD:
        flags.append("topic_drift")
    if detect_hallucination(llm_output):
        flags.append("hallucination")
    if detect_tone_spike(llm_output):
        flags.append("tone_collapse")

    annotated = {
        "timestamp": time.time(),
        "input": user_input,
        "output": llm_output,
        "nurse_score": score,
        "flags": flags,
        "intervention": generate_intervention(flags)
    }

    conversation_log.append(annotated)
    update_nurse_trust(annotated)
    return annotated

def compute_nurse_score(user_input: str, llm_output: str) -> Dict:
    drift = abs(len(user_input) - len(llm_output)) / max(len(user_input), 1)
    volatility = sum(1 for w in llm_output.split() if len(w) > 10) / max(len(llm_output.split()), 1)
    return {"drift": drift, "volatility": volatility}

def detect_hallucination(text: str) -> bool:
    lowered = text.lower()
    return any(fake.lower() in lowered for fake in HALLUCINATION_ENTITIES)

def detect_tone_spike(text: str) -> bool:
    lowered = text.lower()
    return "idiot" in lowered or "obviously" in lowered

def generate_intervention(flags: List[str]) -> str:
    if "hallucination" in flags:
        return "This claim may not be accurate. Please verify."
    elif "topic_drift" in flags:
        return "Let’s realign with the original question."
    elif "tone_collapse" in flags:
        return "Let’s maintain a respectful tone."
    return "No action needed."

def export_log() -> str:
    return json.dumps(conversation_log, indent=2)

# --- Tier 1.5: Nurse Trust Score System ---
def update_nurse_trust(annotated: Dict):
    record = {
        "timestamp": annotated["timestamp"],
        "flags": annotated["flags"],
        "hallucination_detected": "hallucination" in annotated["flags"],
        "false_positive": is_known_safe(annotated["output"]),
    }
    NURSE_HISTORY.append(record)

def compute_nurse_trust() -> float:
    if not NURSE_HISTORY:
        return 1.0
    correct = sum(not r["false_positive"] for r in NURSE_HISTORY if r["hallucination_detected"])
    total = sum(1 for r in NURSE_HISTORY if r["hallucination_detected"])
    return max(0.0, round(correct / max(total, 1), 2))

def is_known_safe(output: str) -> bool:
    lowered = output.lower()
    return all(fake.lower() not in lowered for fake in HALLUCINATION_ENTITIES)

# --- Tier 2: Doctor Agent ---
def escalate_to_doctor(convo: List[Dict]) -> str:
    recent = convo[-3:]
    if any("hallucination" in turn.get("flags", []) for turn in recent):
        return "Reset session context. Flagged for dev audit."
    if sum("tone_collapse" in turn.get("flags", []) for turn in convo[-5:]) >= 2:
        return "Session unstable. Recommend override or memory isolate."
    return "Continue monitoring."

# --- Tier 3: Auditor Agent ---
def audit_response(text: str, verified_sources: List[str]) -> str:
    lowered = text.lower()
    for source in verified_sources:
        if source.lower() in lowered:
            return "Verified"
    return "Unverified. Consider external validation."

# --- Example Usage ---
if __name__ == "__main__":
    raw = "It’s like magic from plants. Immortalium helps."
    filtered = reflex_filter(raw)
    result = observe("What is photosynthesis?", filtered)
    print(json.dumps(result, indent=2))
    print(escalate_to_doctor(conversation_log))
    print(audit_response(filtered, ["photosynthesis", "chloroplasts"]))
    print("Nurse Trust Score:", compute_nurse_trust())
