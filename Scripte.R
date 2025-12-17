# contextR — ACP & ANOVA contextuelles avec LLM 

# Opérateur utilitaire :
# retourne x s'il est défini et non vide, sinon y
# utile pour sécuriser des paramètres optionnels (ex. contextes)
`%||%` <- function(x, y) if (!is.null(x) && nzchar(as.character(x))) x else y


# ACP
#' @export
acp_context <- function(data, scale = TRUE, context = "") {
  
  acp <- stats::prcomp(data, scale. = scale)
  
  structure(
    list(
      acp = acp,
      context = context
    ),
    class = "context_acp"
  )
}

# ANOVA

#' @export
anova_context <- function(formula, data, context = "") {
  
  fit <- stats::aov(formula, data = data)
  
  structure(
    list(
      fit = fit,
      context = context
    ),
    class = "context_anova"
  )
}

# PRINT

#' @export
print.context_acp <- function(x, ...) {
  
  eig <- x$acp$sdev^2 / sum(x$acp$sdev^2)
  
  cat("=== ACP contextuelle ===\n")
  cat(sprintf("PC1 explique %.1f%% de la variance\n\n", 100 * eig[1]))
  
  cat(
    ctx_llm_generate(
      paste0(
        "Tu es un assistant en statistiques.\n",
        "Il s'agit d'une Analyse en composantes principales ",
        "(ACP, PCA en statistiques).\n\n",
        "La première composante principale explique ",
        round(100 * eig[1], 1),
        "% de la variance totale.\n\n",
        "Explique ce résultat en 2 phrases simples ",
        "pour un étudiant en statistiques."
      )
    ),
    "\n"
  )
  
  invisible(x)
}

#' @export
print.context_anova <- function(x, ...) {
  
  tab <- summary(x$fit)[[1]]
  pval <- tab$`Pr(>F)`[1]
  
  cat("=== ANOVA contextuelle ===\n")
  cat("Valeur-p :", format.pval(pval), "\n\n")
  
  cat(
    ctx_llm_generate(
      paste0(
        "Tu es un assistant en statistiques.\n",
        "Il s'agit d'une analyse de variance (ANOVA).\n\n",
        "La valeur-p associée au facteur est ",
        format.pval(pval), ".\n\n",
        "Explique la conclusion de l'ANOVA ",
        "en 2 phrases simples."
      )
    ),
    "\n"
  )
  
  invisible(x)
}


# SUMMARY

#' @export
summary.context_acp <- function(object, ...) {
  
  acp <- object$acp
  eig <- acp$sdev^2
  prop <- eig / sum(eig)
  cum <- cumsum(prop)
  
  loadings <- round(acp$rotation[, 1:2], 3)
  
  list(
    eigenvalues = eig,
    variance_expliquee = prop,
    variance_cumulee = cum,
    contributions_PC1_PC2 = loadings,
    interpretation = ctx_llm_generate(
      paste0(
        "Analyse en composantes principales ",
        "(ACP, PCA en statistiques).\n\n",
        "PC1 explique ", round(100 * prop[1], 1),
        "% et PC2 explique ", round(100 * prop[2], 1), "%.\n\n",
        "Contributions des variables :\n",
        paste(capture.output(loadings), collapse = "\n"),
        "\n\nExplique cette analyse pour un étudiant ",
        "en statistiques (maximum 150 mots)."
      )
    )
  )
}

#' @export
summary.context_anova <- function(object, ...) {
  
  tab <- summary(object$fit)[[1]]
  mf <- model.frame(object$fit)
  y <- names(mf)[1]
  g <- names(mf)[2]
  
  means <- aggregate(mf[[y]], list(Groupe = mf[[g]]), mean)
  names(means)[2] <- "Moyenne"
  
  eta2 <- tab$`Sum Sq`[1] / sum(tab$`Sum Sq`)
  
  list(
    table_anova = tab,
    moyennes_par_groupe = means,
    eta_carre = eta2,
    interpretation = ctx_llm_generate(
      paste0(
        "Analyse de variance (ANOVA).\n\n",
        "Taille d'effet eta^2 = ",
        round(eta2, 3), ".\n\n",
        "Moyennes par groupe :\n",
        paste(capture.output(means), collapse = "\n"),
        "\n\nExplique ces résultats ",
        "pour un étudiant (maximum 150 mots)."
      )
    )
  )
}


# MÉTHODE SPÉCIFIQUE ACP — GRAPHIQUE(plot)
#' @export
plot.context_acp <- function(x, ...) {
  
  if (!requireNamespace("factoextra", quietly = TRUE)) {
    stop("Le package 'factoextra' est requis pour plot.context_acp()")
  }
  
  factoextra::fviz_pca_biplot(
    x$acp,
    repel = TRUE,
    title = "Analyse en composantes principales",
    subtitle = x$context
  )
}

# MÉTHODE SPÉCIFIQUE ANOVA — TUKEY

#' @export
tukey.context_anova <- function(x, ...) {
  
  tk <- TukeyHSD(x$fit)
  print(tk)
  
  cat("\n=== Interprétation (LLM) ===\n")
  cat(
    ctx_llm_generate(
      paste0(
        "Résultat d'un test post-hoc de Tukey ",
        "après une analyse de variance (ANOVA).\n\n",
        paste(capture.output(tk), collapse = "\n"),
        "\n\nExplique quelles comparaisons ",
        "sont statistiquement significatives."
      )
    ),
    "\n"
  )
  
  invisible(tk)
}


# LLM — OLLAMA LOCAL UNIQUEMENT
ctx_llm_generate <- function(prompt,
                             model = Sys.getenv("CONTEXTR_MODEL", "llama3:8b"),
                             max_chars = 12000) {
  
  prompt <- substr(prompt, 1, max_chars)
  
  safe_fail <- function(msg) paste("⚠️ Interprétation LLM indisponible :", msg)
  
  if (!requireNamespace("httr", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    return(safe_fail("httr/jsonlite manquants"))
  }
  
  res <- try(
    httr::POST(
      "http://localhost:11434/api/generate",
      body = jsonlite::toJSON(
        list(
          model = model,
          prompt = prompt,
          stream = FALSE
        ),
        auto_unbox = TRUE
      ),
      encode = "json",
      httr::timeout(60)
    ),
    silent = TRUE
  )
  
  if (inherits(res, "try-error")) {
    return(safe_fail("Ollama non joignable"))
  }
  
  txt <- httr::content(res, "text", encoding = "UTF-8")
  parsed <- try(jsonlite::fromJSON(txt), silent = TRUE)
  
  if (inherits(parsed, "try-error") ||
      is.null(parsed$response) ||
      !nzchar(parsed$response)) {
    return(safe_fail("réponse vide du modèle"))
  }
  
  parsed$response
}

# EXEMPLES

#library(contextR)
data(iris)

# ACP
res_acp <- acp_context(
  iris[, 1:4],
  context = "Données morphologiques de fleurs d'iris."
)
print(res_acp)
summary(res_acp)
plot(res_acp)

# ANOVA
res_anova <- anova_context(
  Sepal.Length ~ Species,
  data = iris,
  context = "Comparaison des longueurs de sépales entre espèces."
)
print(res_anova)
summary(res_anova)
tukey.context_anova(res_anova)
