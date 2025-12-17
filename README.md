# Projet-Fonctions-et-M-thodes

### contextR — Analyse statistique contextuelle avec LLM (Ollama)


## DESCRIPTION

# Le package contextR permet de réaliser des analyses
# statistiques classiques (ACP et ANOVA) tout en générant
# automatiquement des interprétations pédagogiques
# contextualisées à l’aide d’un modèle de langage (LLM).

# Le principe fondamental du package est la séparation
# claire entre :
#  - le calcul statistique (réalisé par R),
#  - l’interprétation textuelle (générée par un LLM).

# Le package utilise exclusivement Ollama en local.
# Aucun service externe n’est sollicité, ce qui garantit
# la reproductibilité, la confidentialité et l’autonomie
# de l’analyse.



### INSTALLATION DU PACKAGE LOCAL
# Le package contextR n’est pas distribué sur le CRAN.
# Il doit être installé localement à partir de son dossier source.

# Étapes :

# 1) Se placer dans le dossier contenant le package contextR

# 2) Installer le package localement :
# install.packages("chemin/vers/contextR", repos = NULL, type = "source")
# ou, si le répertoire courant contient le package :
# install.packages(".", repos = NULL, type = "source")

# 3) Charger le package :
# library(contextR)


### PRÉREQUIS — LLM (OLLAMA)

# Ollama permet d’exécuter des modèles de langage localement.

# Étapes d’installation :

# 1) Télécharger Ollama :
#    https://ollama.com

# 2) Installer Ollama selon votre système d’exploitation

# 3) Lancer le serveur Ollama (si ce n’est pas automatique) :
# ollama serve

## INSTALLATION D’UN MODÈLE

# Par défaut, le package utilise le modèle "llama3".

# Dans un terminal :
# ollama pull llama3

# Vérifier les modèles installés :
# ollama list


# CONFIGURATION (OPTIONNELLE)

# Le modèle utilisé par le package peut être modifié
# via une variable d’environnement R :

# Sys.setenv(CONTEXTR_MODEL = "llama3")



# packageS R

# Le package utilise les packages suivants :

#  - stats (base R)
#  - httr
#  - jsonlite
#  - factoextra (uniquement pour la visualisation ACP)

# Installer les packages manquants :

# install.packages(c("httr", "jsonlite", "factoextra"))


## EXEMPLES REPRODUCTIBLES

# EXEMPLE 1 — ANALYSE EN COMPOSANTES PRINCIPALES (ACP)

# Charger le package et les données
library(contextR)
data(iris)

# Calcul de l’ACP contextuelle
res_acp <- acp_context(
  iris[, 1:4],
  context = "Données morphologiques de fleurs d'iris."
)

# Affichage des résultats
print(res_acp)
summary(res_acp)

# Visualisation ACP
plot(res_acp)

# L’ACP est calculée avec prcomp.
# Les résultats numériques sont affichés par R.
# Une interprétation pédagogique est générée via le LLM.
# Le graphique ACP est affiché sans identifiants d’individus.


# EXEMPLE 2 — ANALYSE DE VARIANCE (ANOVA)


res_anova <- anova_context(
  Sepal.Length ~ Species,
  data = iris,
  context = "Comparaison des longueurs de sépales entre espèces."
)

print(res_anova)
summary(res_anova)

# L’ANOVA est réalisée avec aov.
# Les moyennes par groupe et la taille d’effet (eta²)
# sont calculées et interprétées automatiquement.


# EXEMPLE 3 — TEST POST-HOC DE TUKEY

tukey.context_anova(res_anova)

# Le test de Tukey permet d’identifier les comparaisons
# significatives entre les groupes après l’ANOVA.
# Une interprétation textuelle est générée par le LLM.

## REMARQUES IMPORTANTES

# - Si Ollama n’est pas disponible ou ne répond pas,
#   le package n’échoue pas et affiche un message
#   d’avertissement clair.

# - Les analyses statistiques restent entièrement
#   fonctionnelles, même sans LLM.

# - Le LLM est utilisé uniquement pour l’interprétation
#   des résultats, jamais pour le calcul statistique.

