# dineExpand <img src="https://img.shields.io/badge/version-0.1.0-blue" align="right"/>

**Dining-specific semantic dictionary expander for hospitality research**

[![R-CMD-check](https://github.com/gvajpai/dineExpand/workflows/R-CMD-check/badge.svg)](https://github.com/gvajpai/dineExpand/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`dineExpand` expands seed dictionaries for dining and hospitality research
using word embeddings pre-trained on **512,140 Yelp restaurant reviews**.
Any theoretical construct — revisit intention, food neophobia, authenticity,
service quality, price perception — can be expanded with a single function
call and restaurant-domain vocabulary out of the box.

Built on [lexiExpand](https://github.com/gvajpai/lexiExpand) for the core
similarity engine. Use `dineExpand` when your research is dining-specific;
use `lexiExpand` for any other domain.

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("gvajpai/dineExpand")
```

---

## Quick start

```r
library(dineExpand)

# Step 1 — Load restaurant vectors (~33 MB, one-time download, then cached)
vecs <- load_dining_vectors()

# Step 2 — Expand any dining construct
expand_dining(c("revisit", "return", "loyalty"), vectors = vecs)

# Step 3 — Export
lexiExpand::export_dict(result, name = "revisit_intention", format = "list")
```

---

## Usage examples

### Example 1 — Single seed word

```r
vecs <- load_dining_vectors()

expand_dining("aroma", vectors = vecs, interactive = FALSE)
#>        word similarity  seed pct_match
#> 1     scent      0.841 aroma       84%
#> 2  smokiness      0.823 aroma       82%
#> 3   fragrant      0.809 aroma       81%
#> 4    flavors      0.796 aroma       80%
#> 5     savory      0.781 aroma       78%
```

---

### Example 2 — Vector of seeds (hospitality constructs)

```r
# Revisit intention
expand_dining(
  seed        = c("revisit", "return", "loyalty"),
  n           = 15,
  threshold   = 0.65,
  vectors     = vecs,
  interactive = FALSE
)

# Food neophobia — centroid mode finds words near the concept centre
expand_dining(
  seed        = c("adventurous", "novel", "unfamiliar", "exotic"),
  seed_mode   = "centroid",
  vectors     = vecs,
  interactive = FALSE
)

# Authenticity
expand_dining(
  seed        = c("authentic", "traditional", "genuine", "local"),
  vectors     = vecs,
  interactive = FALSE
)

# Service quality
expand_dining(
  seed        = c("attentive", "courteous", "prompt", "helpful"),
  vectors     = vecs,
  interactive = FALSE
)
```

---

### Example 3 — Custom lexicon data frame (word + dimension)

`expand_dining_lexicon()` accepts any two-column data frame and expands
every dimension in one call.

```r
my_dict <- data.frame(
  word      = c("aroma",     "flavor",    "texture",
                "delighted", "excited",   "moved",
                "revisit",   "return",    "loyal",
                "adventurous","novel",    "unfamiliar"),
  dimension = c("sensory",   "sensory",   "sensory",
                "affect",    "affect",    "affect",
                "revisit",   "revisit",   "revisit",
                "neophobia", "neophobia", "neophobia")
)

candidates <- expand_dining_lexicon(
  my_dict,
  n         = 15,
  threshold = 0.65,
  vectors   = vecs
)

# Results include a $dimension column
table(candidates$dimension)
#>     affect  neophobia    revisit    sensory
#>         14         12         13         17

# Export as quanteda dictionary
library(quanteda)
lexiExpand::export_dict(
  candidates,
  seed   = my_dict$word,
  name   = "dining_constructs",
  format = "quanteda"
)
```

---

## Train on your own corpus

Supply your own restaurant reviews to train domain-specific vectors:

```r
library(data.table)
reviews <- fread("my_reviews.csv")

vecs_custom <- train_dining_vectors(
  texts      = reviews$text,
  dims       = 100L,
  cache_path = "~/my_restaurant_vectors.rds"
)

expand_dining(c("aroma", "flavor"), vectors = vecs_custom)
```

---

## How the default vectors were trained

| Property | Value |
|---|---|
| Corpus | Yelp Open Dataset — restaurant reviews |
| Reviews | 512,140 |
| Algorithm | GloVe (Pennington et al., 2014) |
| Dimensions | 100 |
| Window size | 5 |
| Iterations | 20 |
| Vocabulary | ~98,000 terms |
| File size | 33.2 MB |

Restaurant-specific vocabulary clusters meaningfully in this space.
For example, `attentive` → `waitstaff`, `knowledgeable`, `courteous`,
`prompt`; and `aroma` → `smokiness`, `savoriness`, `fragrant` — terms that
would rank far lower in Wikipedia-trained embeddings.

---

## Function reference

| Function | Description |
|---|---|
| `load_dining_vectors()` | Download & cache Yelp-trained vectors (run once) |
| `expand_dining()` | Expand a seed word or vector of seeds |
| `expand_dining_lexicon()` | Expand a full lexicon data frame by dimension |
| `train_dining_vectors()` | Train custom vectors from your own corpus |
| `lexiExpand::export_dict()` | Export to list, data.frame, or quanteda dictionary |

---

## Related packages

| Package | Purpose |
|---|---|
| [lexiExpand](https://github.com/gvajpai/lexiExpand) | General-purpose semantic expander (any domain) |
| [mdeinR](https://github.com/gvajpai/mdeinR) | Memorable Dining Experience dictionary and scoring |

---

## Citation

If you use `dineExpand` in published research, please cite:

> Vajpai, G. N. (2025). *dineExpand: Dining-Specific Semantic Dictionary
> Expander for Hospitality Research*. R package version 0.1.0.
> https://github.com/gvajpai/dineExpand

---

## License

MIT © 2025 Gopi Nath Vajpai
