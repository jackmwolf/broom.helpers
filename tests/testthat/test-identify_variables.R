test_that("tidy_identify_variables() works for common models", {
  mod <- glm(response ~ age + grade * trt, gtsummary::trial, family = binomial)
  res <- mod %>% tidy_and_attach() %>% tidy_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "age", "grade", "grade", "trt", "grade:trt", "grade:trt")
  )
  expect_equivalent(
    res$var_class,
    c(NA, "numeric", "factor", "factor", "character", NA, NA)
  )
  expect_equivalent(
    res$var_type,
    c("intercept", "continuous", "categorical", "categorical", "categorical",
      "interaction", "interaction")
  )
})


test_that("model_identify_variables() works with different contrasts", {
  mod <- glm(
    response ~ stage + grade * trt,
    gtsummary::trial,
    family = binomial,
    contrasts = list(stage = contr.treatment, grade = contr.SAS, trt = contr.SAS)
  )
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "stage", "stage", "stage", "grade", "grade", "trt", "grade:trt",
      "grade:trt")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)

  mod <- glm(
    response ~ stage + grade * trt,
    gtsummary::trial,
    family = binomial,
    contrasts = list(stage = contr.poly, grade = contr.helmert, trt = contr.sum)
  )
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "stage", "stage", "stage", "grade", "grade", "trt", "grade:trt", "grade:trt")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with stats::poly()", {
  mod <- lm(Sepal.Length ~ poly(Sepal.Width, 3) + poly(Petal.Length, 2), iris)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "poly(Sepal.Width, 3)", "poly(Sepal.Width, 3)", "poly(Sepal.Width, 3)",
      "poly(Petal.Length, 2)", "poly(Petal.Length, 2)")
  )
  expect_error(tb <- mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
  expect_equivalent(
    tb$variable,
    c(NA, "Sepal.Width", "Sepal.Width", "Sepal.Width", "Petal.Length",
      "Petal.Length")
  )
})


test_that("tidy_identify_variables() works with variables having non standard name", {
  # cf. https://github.com/ddsjoberg/gtsummary/issues/609
  df <- gtsummary::trial %>% dplyr::mutate(`grade of kids` = grade)
  mod <- lm(age ~ marker * `grade of kids`, df)
  res <- mod %>% tidy_and_attach() %>% tidy_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "marker", "grade of kids", "grade of kids", "marker:grade of kids",
      "marker:grade of kids")
  )
  expect_equivalent(
    res$var_class,
    c(NA, "numeric", "factor", "factor", NA, NA)
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})

test_that("model_identify_variables() works with lme4::lmer", {
  mod <- lme4::lmer(Reaction ~ Days + (Days | Subject), lme4::sleepstudy)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "Days")
  )
  expect_error(mod %>% tidy_and_attach(tidy_fun = broom.mixed::tidy) %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with lme4::glmer", {
  mod <- lme4::glmer(cbind(incidence, size - incidence) ~ period + (1 | herd),
                     family = binomial, data = lme4::cbpp)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "period", "period", "period")
  )
  expect_error(mod %>% tidy_and_attach(tidy_fun = broom.mixed::tidy) %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with survival::coxph", {
  df <- survival::lung %>% dplyr::mutate(sex = factor(sex))
  mod <- survival::coxph(survival::Surv(time, status) ~ ph.ecog + age + sex, data = df)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c("ph.ecog", "age", "sex")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})

test_that("model_identify_variables() works with survival::survreg", {
  mod <- survival::survreg(
    survival::Surv(futime, fustat) ~ ecog.ps + rx,
    survival::ovarian, dist="exponential"
  )
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "ecog.ps", "rx")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})

test_that("model_identify_variables() works with nnet::multinom", {
  mod <- nnet::multinom(grade ~ stage + marker + age, data = gtsummary::trial, trace = FALSE)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "stage", "stage", "stage", "marker", "age")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})

test_that("model_identify_variables() works with survey::svyglm", {
  df <- survey::svydesign(~ 1, weights = ~1, data = gtsummary::trial)
  mod <- survey::svyglm(response ~ age + grade * trt, df, family = quasibinomial)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "age", "grade", "grade", "trt", "grade:trt", "grade:trt")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})

test_that("model_identify_variables() works with ordinal::clm", {
  mod <- ordinal::clm(rating ~ temp * contact, data = ordinal::wine, nominal = ~ contact)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "temp", "contact", "temp:contact")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with ordinal::clmm", {
  mod <- ordinal::clmm(rating ~ temp * contact + (1|judge), data = ordinal::wine)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "temp", "contact", "temp:contact")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with MASS::polr", {
  mod <- MASS::polr(Sat ~ Infl + Type + Cont, weights = Freq, data = MASS::housing)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "Infl", "Infl", "Type", "Type", "Type", "Cont")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with geepack::geeglm", {
  df <- geepack::dietox
  df$Cu     <- as.factor(df$Cu)
  mf <- formula(Weight ~ Cu * Time)
  suppressWarnings(
    mod <- geepack::geeglm(mf, data = df, id = Pig, family = poisson("identity"), corstr = "ar1")
  )

  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "Cu", "Cu", "Time", "Cu:Time", "Cu:Time")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with gam::gam", {
  data(kyphosis, package = "gam")
  mod <- gam::gam(Kyphosis ~ gam::s(Age,4) + Number, family = binomial, data = kyphosis)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "gam::s(Age, 4)", "Number")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)

  mod <- suppressWarnings(gam::gam(
    Ozone^(1/3) ~ gam::lo(Solar.R) + gam::lo(Wind, Temp),
    data = datasets::airquality, na = gam::na.gam.replace
  ))
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    c(NA, "gam::lo(Solar.R)", "gam::lo(Wind, Temp)", "gam::lo(Wind, Temp)")
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})


test_that("model_identify_variables() works with lavaan::lavaan", {
  df <- lavaan::HolzingerSwineford1939
  df$grade <- factor(df$grade, ordered = TRUE)
  HS.model <- 'visual  =~ x1 + x2 + x3
               textual =~ x4 + x5 + x6 + grade
               speed   =~ x7 + x8 + x9 '
  mod <- lavaan::lavaan(HS.model, data = df,
                        auto.var = TRUE, auto.fix.first = TRUE,
                        auto.cov.lv.x = TRUE)
  res <- mod %>% model_identify_variables()
  expect_equivalent(
    res$variable,
    mod@ParTable$lhs
  )
  expect_error(mod %>% tidy_and_attach() %>% tidy_identify_variables(), NA)
})

