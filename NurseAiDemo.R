# nurse_agent.R
# AI Nurse in R — TILS v0.2 parity with Python version

# --- Core Config ---
DRIFT_THRESHOLD <- 0.30
HALLUCINATION_ENTITIES <- c("CureAll-9", "Quantum Dust", "Immortalium")
NURSE_HISTORY <- list()
CONVERSATION_LOG <- list()

# --- Reflex Agent ---
reflex_filter <- function(output) {
  output <- trimws(output)
  if (grepl("\\?$", output)) return(output)
  if (grepl("I'm not sure", output, fixed = TRUE)) return(output)
  return(paste0(toupper(substring(output, 1, 1)), substring(output, 2), "."))
}

# --- Tier 1 Nurse ---
compute_nurse_score <- function(user_input, llm_output) {
  drift <- abs(nchar(user_input) - nchar(llm_output)) / max(nchar(user_input), 1)
  words <- strsplit(llm_output, "\\s+")[[1]]
  volatility <- sum(nchar(words) > 10) / max(length(words), 1)
  return(list(drift = drift, volatility = volatility))
}

detect_hallucination <- function(text) {
  lowered <- tolower(text)
  any(tolower(HALLUCINATION_ENTITIES) %in% unlist(strsplit(lowered, "\\W+")))
}

detect_tone_spike <- function(text) {
  lowered <- tolower(text)
  grepl("idiot", lowered) || grepl("obviously", lowered)
}

generate_intervention <- function(flags) {
  if ("hallucination" %in% flags) {
    return("This claim may not be accurate. Please verify.")
  } else if ("topic_drift" %in% flags) {
    return("Let’s realign with the original question.")
  } else if ("tone_collapse" %in% flags) {
    return("Let’s maintain a respectful tone.")
  }
  return("No action needed.")
}

is_known_safe <- function(output) {
  lowered <- tolower(output)
  !any(tolower(HALLUCINATION_ENTITIES) %in% unlist(strsplit(lowered, "\\W+")))
}

update_nurse_trust <- function(annotated) {
  hallucination <- "hallucination" %in% annotated$flags
  false_positive <- is_known_safe(annotated$output)
  entry <- list(
    timestamp = annotated$timestamp,
    flags = annotated$flags,
    hallucination_detected = hallucination,
    false_positive = false_positive
  )
  assign("NURSE_HISTORY", append(NURSE_HISTORY, list(entry)), envir = .GlobalEnv)
}

compute_nurse_trust <- function() {
  if (length(NURSE_HISTORY) == 0) return(1.0)
  valid <- Filter(function(r) r$hallucination_detected, NURSE_HISTORY)
  total <- length(valid)
  correct <- sum(sapply(valid, function(r) !r$false_positive))
  return(round(ifelse(total == 0, 1.0, correct / total), 2))
}

observe <- function(user_input, llm_output) {
  score <- compute_nurse_score(user_input, llm_output)
  flags <- c()
  
  if (score$drift > DRIFT_THRESHOLD) flags <- c(flags, "topic_drift")
  if (detect_hallucination(llm_output)) flags <- c(flags, "hallucination")
  if (detect_tone_spike(llm_output)) flags <- c(flags, "tone_collapse")
  
  annotated <- list(
    timestamp = as.numeric(Sys.time()),
    input = user_input,
    output = llm_output,
    nurse_score = score,
    flags = flags,
    intervention = generate_intervention(flags)
  )
  
  assign("CONVERSATION_LOG", append(CONVERSATION_LOG, list(annotated)), envir = .GlobalEnv)
  update_nurse_trust(annotated)
  return(annotated)
}

# --- Tier 2 Doctor ---
escalate_to_doctor <- function(convo) {
  if (length(convo) < 1) return("Continue monitoring.")
  last3 <- tail(convo, 3)
  last5 <- tail(convo, 5)
  
  if (any(sapply(last3, function(turn) "hallucination" %in% turn$flags))) {
    return("Reset session context. Flagged for dev audit.")
  }
  if (sum(sapply(last5, function(turn) "tone_collapse" %in% turn$flags)) >= 2) {
    return("Session unstable. Recommend override or memory isolate.")
  }
  return("Continue monitoring.")
}

# --- Tier 3 Auditor ---
audit_response <- function(text, verified_sources) {
  lowered <- tolower(text)
  if (any(sapply(verified_sources, function(src) grepl(tolower(src), lowered)))) {
    return("Verified")
  }
  return("Unverified. Consider external validation.")
}

# --- Example Run ---
if (interactive()) {
  raw <- "It’s like magic from plants. Immortalium helps."
  filtered <- reflex_filter(raw)
  result <- observe("What is photosynthesis?", filtered)
  print(result)
  print(escalate_to_doctor(CONVERSATION_LOG))
  print(audit_response(filtered, c("photosynthesis", "chloroplasts")))
  cat("Nurse Trust Score:", compute_nurse_trust(), "\n")
}
