# Pain and motor severity in early Parkinson disease covary without detectable temporal precedence: a six-wave analysis of the Parkinson's Progression Markers Initiative

## Abstract

**Importance.** Pain accompanies greater motor severity in Parkinson disease, and most claims about the relationship assign a direction, usually from motor disease to pain. The longitudinal models used do not separate stable differences between patients from change within a patient, which is the distinction the question turns on.

**Objective.** To determine whether self-reported pain and motor severity in early Parkinson disease are related by temporal precedence, and to characterise the relationship if it is not sequential.

**Design, setting and participants.** Cohort study using six annual assessments from the Parkinson's Progression Markers Initiative. 1,174 participants contributed 3,180 assessments; 711 formed the 12-month cross-section.

**Exposures.** Self-reported pain and other bodily sensations, measured by MDS-UPDRS item 1.9.

**Main outcomes and measures.** MDS-UPDRS Part III, examined off medication or before treatment. The primary temporal analysis was a random-intercept cross-lagged panel model, which separates stable between-person differences from within-person change; the conventional cross-lagged panel model was fitted alongside it for comparison. Attrition was handled by inverse probability of censoring weighting^1^ with a weighted generalised estimating equation, and dopaminergic dose by a marginal structural model. Specificity was assessed against depression as an alternative exposure, against cognition as an alternative outcome, and against healthy control and prodromal cohorts.

**Results.** Mean age was 63.7 years (SD 9.6); 65.5% were male. A conventional cross-lagged model made both directions significant (pain to motor p = 0.004; motor to pain p = 0.008). Separating stable between-person differences fit substantially better (CFI 0.963/0.877, RMSEA 0.077/0.114, SRMR 0.044/0.112) and eliminated the motor-to-pain path. In the unconstrained model, which is primary because the equality constraints are rejected, the motor-to-pain path reached significance in 0 of 5 waves and the pain-to-motor path in 1; neither is claimed. What remained was a stable between-person correlation (r = 0.152, p = 0.011), unchanged when both random intercepts were adjusted for baseline covariates (r = 0.171). Baseline pain marked a persistently higher motor score (1.396 points per pain point, p = <0.001) but not a steeper slope (p = 0.189), below the minimal clinically important difference and independent of striatal dopamine transporter binding (0.011, p = 0.766, against -0.219 for motor severity). A stable index of reporting tendency was strongly associated with pain (0.419 SD) and accounted for 77% of the correlation with patient-reported motor function but not the correlation with the examined score. Five converging analyses indicated the covariation is not specific to pain, including a general factor leaving no residual association (p = 0.227), a correlation of similar magnitude in 307 healthy controls that the data cannot distinguish from the patient estimate (difference p = 0.885), and other non-motor items covarying as strongly (0.277 for insomnia against 0.159 for pain).

**Conclusions and relevance.** In early Parkinson disease, pain and motor severity covary as stable characteristics of the patient, and neither precedes the other at the annual resolution this cohort can resolve, although the modest within-person reliability of a single ordinal item limits power to detect such coupling. The covariation is small, below the threshold for clinical relevance, independent of striatal dopaminergic loss, and not specific to pain: it is better read as an index of general early non-motor burden. The reciprocal causation that a conventional cross-lagged model reports on these same data is an artefact of not separating between-person from within-person variation, which bears on how directionality has been claimed in this literature.

---

## Introduction

Pain is among the most common non-motor features of Parkinson disease, affecting roughly two thirds of patients,^2^^3^^4^ and is repeatedly found to accompany greater motor impairment. The mechanistic accounts proposed for this association are plausible and varied: basal ganglia participation in nociceptive processing,^5^^6^ altered sensory gating, dopaminergic modulation of pain threshold,^7^^8^ and altered nociceptive processing in structures downstream of dopaminergic loss, shown in lesion models.^9^

What these accounts share is an assumption about order. Most of the literature that assigns a direction assigns it from motor disease to pain: pain is treated as a consequence of rigidity, of dystonia, or of fluctuation in dopaminergic state.^10^ The evidence is not unanimous. Shoulder pain and stiffness are recorded more often two years before diagnosis, although that study classifies them as motor rather than non-motor features,^11^ a quarter of patients with pain report its onset before starting antiparkinsonian therapy,^2^ and musculoskeletal pain has been argued not to arise as a direct sequel of motor symptoms.^12^ The possibility that neither precedes the other has received almost no attention.

The reason this remains unsettled is methodological rather than substantive. Cross-sectional designs measure both quantities on the same day and cannot invoke temporal order. The longitudinal designs used so far, when they estimate lagged effects at all, use models that confound two different sources of variation. If patients differ stably in how much pain and how much motor impairment they carry, a conventional cross-lagged panel model may report the presence, predominance or sign of lagged effects erroneously, purely from that stable covariation and without anyone moving in response to anyone else.^13^ Distinguishing "patients with more pain have more motor impairment" from "when a patient's pain rises, their motor score rises afterwards" requires a model that separates the two. That separation has been applied in this cohort to anxiety and depression against physical function, where no within-person coupling with the examined motor score was found although coupling with patient-reported function was, for depression,^14^ and in a different Parkinson cohort to cognition and mood,^15^ but not to pain.

A second complication is specific to Parkinson disease. Dopaminergic dose responds to symptoms and in turn affects both later symptoms and later dose. It is therefore a time-varying confounder affected by prior exposure, the canonical situation in which conventional regression is biased whether or not the confounder is adjusted for.^16^^17^

We used six annual assessments from a large cohort of recently diagnosed patients to address three questions. First, whether pain and motor severity are related by temporal precedence in either direction once stable between-person differences are separated from within-person change. Second, whether pain is associated with the level of motor impairment, its rate of progression, or both, with attrition modelled explicitly. Third, what the association becomes when dopaminergic dose is handled as a time-varying confounder rather than as an ordinary covariate.

We also tested a specific mechanistic prediction. If the association reflects shared pathophysiology rather than confounding, pain should concentrate in the akinetic-rigid presentation, which prior work supports,^18^^19^ and its association with motor severity should be stronger there, which no prior study has tested.

---

## Methods

Figure 1 summarises the analytic strategy: which question each estimator answers and what it produced. Figure 7 gives the causal assumptions behind each estimator as directed acyclic graphs, following the convention that a double box marks a variable the analysis conditions on. The four panels correspond to the four structures the design has to resolve: why a conventional cross-lagged model reports both directions, what each component estimates once between-person and within-person variation are separated, dopaminergic dose as a time-varying confounder affected by prior exposure, and the structure of censoring by attrition.

### Study design and participants

We analysed data from the Parkinson's Progression Markers Initiative, an international multicentre observational cohort of recently diagnosed, initially untreated Parkinson disease. We used the baseline visit and the five subsequent annual visits.

Eligibility followed a frozen enrolment flow. Of 14,473 records in the curated release, 2,614 corresponded to the 12-month visit, of which 1,121 were in the Parkinson disease cohort. We excluded participants with monogenic forms (LRRK2, SNCA, PRKN, PINK1), leaving 913; carriers of GBA variants were retained, since GBA is a risk variant rather than a deterministic monogenic form. We then excluded participants who had received deep brain stimulation on or before the visit date, leaving 911.

Exclusion for deep brain stimulation was applied by comparing the date of the first recorded procedure with the visit date. Marking every participant who ever received stimulation, including years later, conditions on the future and systematically removes the patients who progress most, who are precisely the surgical candidates.

Complete pain data left 860 participants and complete motor data left 711, the analytic sample at 12 months.

Four populations recur in this paper and are defined once here, because they are easy to conflate. The baseline cohort is 1,190 eligible participants; 1,157 of these have both pain and motor data at baseline and form the denominator for every retention figure. Across the six waves, 1,174 participants contribute 3,180 assessments with both measures. The 12-month cross-section is 711. All four derive from a single script and cannot diverge.

### Exposure, and what it can and cannot support

Pain was measured with item 1.9 of the MDS-UPDRS. The item is titled "Pain and Other Sensations" and asks the patient to rate, over the past week, uncomfortable feelings in the body including pain, aching, tingling and cramping, on five levels from 0 to 4. It was analysed both as the ordinal score and dichotomised as present (1 or above) versus absent.

Three consequences follow and constrain every claim in this paper. First, the item aggregates pain of different mechanisms, musculoskeletal, dystonic, central, neuropathic and radicular, which the current classification treats as distinct entities requiring distinct management, and which it now organises along nociceptive, neuropathic and nociplastic axes rather than by these older categories.^20^^4^ Nothing here can be attributed to a pain subtype. Second, the item includes sensations that are not pain, so part of the exposure is paraesthesia rather than nociception. Third, we could find no validation of item 1.9 against a pain-specific instrument. MDS-UPDRS Part I has been validated as a total score against composite non-motor batteries,^21^^22^ which does not license item-level use as a pain measure.

The prevalence we observe, 58.4% at 12 months, replicates the 57 per cent reported for this item at the same visit in this cohort,^23^ and is lower than the two thirds reported with dedicated instruments,^2^^4^ which is consistent with misclassification of the exposure. It is also below the 62.8 per cent reported in age-matched controls in the same case-control study, and that study found no difference between patients and controls in non-dystonic pain.^2^ We therefore describe the exposure throughout as self-reported pain and other bodily sensations, and we do not claim to have measured Parkinson disease pain as that construct is currently defined.

A further caveat applies to the later waves. The item asks about the preceding week, which for a treated patient with motor fluctuations spans both on and off periods,^24^ a state dependence that is well documented.^10^ The answer of a fluctuating patient is therefore not strictly commensurate with that of an untreated one, even though the motor examination itself is in a defined state.

### Outcome

The outcome was the MDS-UPDRS Part III total, examined off medication or before treatment initiation. The Parkinson's Progression Markers Initiative records up to two Part III examinations per visit; we verified that the curated off-state score corresponds to records with a practically defined off state or no recorded medication state, and used those records throughout so that exposure, phenotype and outcome refer to a single clinical state. The on-state score was used in sensitivity analyses.

Disease duration was recomputed at each visit as age at visit minus age at symptom onset. The duration variable distributed with the cohort is fixed at baseline and does not advance between visits, which would understate duration at follow-up by roughly two years.

### Motor phenotype

We classified the tremor dominant and postural instability and gait difficulty phenotypes using the ratio of Stebbins et al.,^25^ defined as the mean of 11 tremor items divided by the mean of 5 postural instability and gait items, drawn from Parts II and III of the MDS-UPDRS. A ratio at or above 1.15 defines tremor dominance, at or below 0.90 defines postural instability and gait difficulty, and values in between are indeterminate.

In a recently diagnosed cohort a substantial minority has no axial signs at all, so the denominator is exactly zero and the ratio is undefined. This affected 19.4% of the analytic sample at 12 months. We were unable to verify that the source article^25^ specifies a rule for this case, and a review of studies applying the criterion found none that states one. We therefore pre-specified the convention inherited from the earlier Jankovic ratio, in which a zero denominator with any tremor is classified as tremor dominant and a patient with neither is indeterminate, and we report two alternatives as sensitivity analyses: classifying all such cases as indeterminate, and excluding them.

Because the classifier and the outcome share items, we constructed a motor score excluding the 13 Part III items used for classification and repeated the phenotype analyses with it. We also rebuilt the ratio separately from examiner-rated Part III items and from patient-reported Part II items, to test whether any apparent effect modification was shared-method correlation.

### Statistical analysis

The adjustment set for the regression models was age, sex, disease duration and MoCA. The panel models are deliberately unadjusted, because random intercepts absorb every time-invariant confounder of the within-person paths, which is the reason for using them. That argument does not protect the between-person trait correlation, so we estimated it again with both random intercepts regressed on the same baseline covariates. Hoehn and Yahr stage was deliberately excluded: it is by construction a staging of motor function and therefore a coarse measurement of the outcome, so conditioning on it is overadjustment rather than confounding control.

**Temporal precedence.** We fitted a random-intercept cross-lagged panel model^13^ across the six waves, in which a random intercept per construct captures stable between-person differences and the cross-lagged paths are estimated on within-person deviations from each patient's own level. We fitted the conventional cross-lagged panel model for contrast. Both used full information maximum likelihood with a robust estimator. We tested the tenability of the across-wave equality constraints by likelihood ratio test and, since they were rejected, report the wave-specific paths.

**Robustness of the within-person path.** Any surviving cross-lagged path was subjected to seven checks: freeing the equality constraints, wave-specific estimation, restriction to the three earliest waves where attrition is least, addition of baseline auxiliary variables as saturated correlates, dichotomisation of the exposure, substitution of the on-state motor score, and a negative control substituting MoCA for the motor outcome.

**The fixed-slope assumption of the random-intercept model.** A random intercept holds each patient's level constant over follow-up. In a progressing disease, patients who differ in the rate at which they worsen have no parameter to occupy, and that between-person variation is forced into the component the model treats as within-person. We therefore refitted the model as a latent curve model with structured residuals,^26^ adding a latent slope per construct so that the cross-lagged paths are estimated on deviations from each patient's own trajectory rather than from their own mean. The slope loadings were centred at the midpoint of follow-up. This is not cosmetic: with loadings running from zero the intercept becomes the baseline level rather than the average level, and the correlation between intercepts then answers a different question. We fitted both parameterisations to show what changes with the origin of time and what does not.

**Level versus slope, and attrition.** We fitted a linear mixed model with random intercept and random slope, testing the interaction between baseline pain and elapsed time. Time was the actual interval from each patient's baseline computed from visit dates, not the nominal visit number. We modelled retention at each visit by logistic regression on baseline characteristics, and constructed stabilised inverse probability of censoring weights, truncated at the 1st and 99th percentiles. Every longitudinal result is reported weighted and unweighted. We report the analysis of covariance and the change score specifications side by side, since they answer different questions and Lord's paradox applies.^27^^28^^29^

**Time-varying confounding.** We first verified empirically that dopaminergic dose behaves as a confounder affected by prior exposure, by testing whether prior pain predicts current dose conditional on prior dose, and whether prior dose predicts current pain conditional on prior pain. We then fitted a marginal structural model^16^^30^ with stabilised inverse probability of treatment weights, accumulated multiplicatively over follow-up and truncated at the 1st and 99th percentiles, and assessed balance on prior dose. Confidence intervals were obtained by resampling whole patients with the weights re-estimated inside each replicate, because the sandwich estimator treats estimated weights as known and is anticonservative. We also computed a substitution estimate holding the time-varying covariates at their observed values. That quantity is not the g-formula, because a confounder affected by prior exposure must be simulated forward under each regime rather than fixed; we report it as a descriptive cross-check and not as independent corroboration.

**Effect modification.** We estimated the pain by phenotype interaction and the effect stratified by phenotype, with the phenotype classified at baseline and the outcome at 12 months to reduce circularity. The pre-specified primary specification was the full MDS-UPDRS Part III outcome, the ordinal exposure and the baseline phenotype. All other combinations were sensitivity analyses, and we report Holm and Benjamini-Hochberg corrections across the full grid.

**Sensitivity to unmeasured confounding.** E-values^31^ were computed on the standardised scale, using the standard deviation of the outcome, not on the raw coefficient. What counts as a large E-value is context dependent, and an E-value can support robustness but cannot demonstrate that no effect exists.^32^

**Multiplicity.** The pipeline exports 323 hypothesis tests. We classified them before interpretation into 20 primary contrasts, 86 pre-specified sensitivity variants of those, and 217 exploratory tests, the last of which are mostly deliberate attempts to refute a result. Correction for multiplicity is applied within the three families where a family is well defined: the seven baseline symptoms, the eight phenotype contrasts and the five motor domains. We do not apply a global correction, because the categories are not exchangeable and because correcting a refutation attempt would inflate exactly the error that matters there. Unqualified language about statistical significance is reserved for the primary category, and the full inventory is in the repository.

Analyses used R 4.5.1. Reporting follows STROBE. The pre-specification, and every methodological decision that changed a result, is recorded in dated architecture decision records in the accompanying repository.

---

## Results

### Participants

At the 12-month visit the analytic sample comprised 711 participants with a mean age of 63.7 years (SD 9.6), of whom 65.5% were male, with mean disease duration of 3.42 years (SD 1.92) and mean MDS-UPDRS Part III of 26.0 (SD 11.2). Pain was reported by 58.4%. Median levodopa equivalent daily dose was 100 mg.

Retention fell from 1,157 participants with both measures at baseline to 236 at year 5 (20.4%; Figure 3). Baseline pain did not predict dropout at any horizon (smallest p = 0.130). Baseline motor severity did, increasingly so with time (OR 0.967 per point at year 5, p = <0.001). Attrition therefore depends on the outcome but not on the exposure. Stabilised censoring weights built from baseline predictors were close to one (means 0.966 to 0.999; range 0.46 to 2.24). Weights close to one indicate a censoring model with little discrimination, which is equally consistent with attrition being near-random given what was measured and with the model being underfit against predictors that change over time.

We therefore refitted the censoring model sequentially, conditioning on remaining at the previous visit and adding that visit's pain, motor score, MoCA and dose. Those weights are not more dispersed: the largest standard deviation is 0.412 against 0.421 for the baseline-only version. Adding the previous visit's pain, motor score, cognition and dose therefore did not reveal informative censoring that the baseline model had missed, which is the more reassuring of the two possible readings but also means we cannot claim to have ruled the alternative out by fitting a richer model. Their means remain close to one (0.934 to 0.999). Refitting the weighted model with them gives a level effect of 1.543 (p = 0.036) and a slope interaction of p = 0.472, so the substantive conclusions hold under either weighting. What we can say is bounded accordingly: censoring is weakly informative given the measured history, not that attrition is harmless.

### Neither direction precedes the other

The conventional cross-lagged panel model reproduced the pattern reported in earlier work on this cohort: both directions significant, with pain predicting later motor severity (p = 0.004) and motor severity predicting later pain (p = 0.008).

Separating stable between-person differences changed this (Figure 2). The random-intercept model fit substantially better (CFI 0.960 vs 0.877; RMSEA 0.067 vs 0.114; SRMR 0.069 vs 0.112). In it the motor-to-pain path was null (p = 0.132). What the conventional model had been reading as reciprocal causation was a stable correlation between the two series across patients: r = 0.175 (p = 0.006).

In the unconstrained model, which is primary because the across-wave equality constraints are rejected, neither cross-lagged direction is consistent across waves: motor to pain reached significance in 0 of 5 waves (smallest p = 0.159) and pain to motor in 1 (smallest p = 0.032), the first transition only. The constrained model, reported alongside for comparability with the literature, gives p = 0.132 and p = 0.013 for the two directions. We claim neither. The across-wave equality constraints that produce it were rejected (p = 0.041), and when the paths were freed only 1 of 5 waves reached significance, the first. Across the six robustness specifications the path survived 2: it disappeared when the exposure was dichotomised, when the on-state motor score was used, and when analysis was restricted to the three earliest waves. The negative control behaved as intended for the cross-lagged path, with no path from pain to later MoCA. It did not behave as intended for the trait correlation, which is the parameter this paper actually reports: pain and MoCA covary stably at r = -0.157 (p = 0.033), about the same magnitude as pain and motor severity. The control fails on the parameter of interest, and that failure is part of the evidence that the covariation is not specific to motor function.

Two conclusions follow. Reciprocal causation between pain and motor severity is not supported. Neither is precedence in either direction.

We also examined why an earlier analysis of this cohort had found asymmetry over the baseline to 12-month window. The two directions had been estimated on different sets of participants, because pain is recorded for more people than the motor examination. Fitted on each direction's own maximal set, the motor-to-pain path reaches the conventional threshold (n = 825, p = 0.015); fitted on the common complete panel, where both directions use the same 698 participants, it does not (p = 0.116). The point estimates are positive either way. The asymmetry was an artefact of the analysis set, not a temporal fact.

### Allowing patients to differ in rate does not change what the model reports

The random intercept assumes a common rate of change. That assumption is not tenable here: adding a latent slope to each construct improved fit by a large margin (likelihood ratio 39.5 on 7 degrees of freedom, p = <0.001; CFI 0.983 vs 0.960, RMSEA 0.047 vs 0.067, SRMR 0.043 vs 0.069). The improvement is not evenly shared between the two constructs. Between-person variance in rate was appreciable for motor severity (1.704, p = 0.079) and indistinguishable from zero for pain (0.006, p = 0.376), which is what a progressing motor scale and a stationary single item should look like.

The assumption was therefore violated, and relaxing it left the paper's conclusion where it was. The trait correlation moved from 0.175 to 0.189 (p = 0.010), a shift of 0.014, against the equality-constrained model used for this comparison rather than the unconstrained model that is primary elsewhere. Neither within-person direction was significant once rates were free (pain to motor p = 0.160, motor to pain p = 0.419). The one nominally significant within-person path in the constrained model, pain to later motor severity at p = 0.013, does not survive (0.160), which is the same conclusion the wave-specific analysis reached by a different route: that path was partly an artefact of forcing all patients to progress at one rate. Information criteria disagree about which model to prefer, as they should when a large fit gain costs seven parameters in a well-powered sample (AIC 33,093 vs 33,126; BIC 33,316 vs 33,314), and we report the random-intercept model as primary for comparability with the literature that uses it.

One detail of this analysis is worth stating because it would otherwise generate a spurious finding. With slope loadings running from zero at baseline, the same model gives a trait correlation of 0.242 rather than 0.189, with identical fit, because the intercept has silently become the baseline level instead of the average level. The larger number is a property of where the origin of time is placed, not of the data.

### The relationship is much larger when the outcome is also self-reported

Because the exposure is patient-reported and the primary outcome is examiner-rated, we refitted the same model with MDS-UPDRS Part II, which measures motor experiences of daily living by patient report, as a parallel outcome.

The trait correlation was 0.533 (p = <0.001), more than three times the 0.152 obtained with the examined motor score. The within-person paths also changed: pain no longer predicted later self-reported function (p = 0.831), whereas self-reported function predicted later pain (0.033, 95% CI 0.019 to 0.047, p = <0.001).

Two readings are available, and the next section separates them. A large part of what is measured as a pain and motor relationship may be shared method variance, since both quantities then come from the same person on the same questionnaire; a threefold difference in the trait correlation is the signature such variance would leave. Alternatively, the relationship may genuinely live in the patient's experience of function rather than in the neurological examination, which would make the direction we recover, from experienced function to later pain, the substantive one.

One observation favours the first reading. The same dissociation, coupling with patient-reported function and none with the examination, has been reported in this cohort for depression.^14^ Two unrelated exposures producing the same pattern against the same pair of outcomes is more parsimoniously explained by how the outcomes are measured than by two independent substantive stories. Either way, the choice of motor outcome matters more than the choice of estimator, and studies that use patient-reported motor scales are not measuring the same relationship as those that use the examination.

### Pain marks a level, not a rate of progression

Baseline pain was associated with a persistently higher motor score across follow-up: 1.396 points of MDS-UPDRS Part III per point of pain (95% CI 0.633 to 2.159, p = <0.001). The interaction with time was null (0.188, 95% CI -0.092 to 0.468, p = 0.189). Weighting for censoring left both unchanged (level 1.481, p = 0.016; slope p = 0.433; Figure 3).

Pain therefore marks a higher level of motor impairment, not a faster rate of deterioration.

The analysis of covariance over the first year gave 1.072 points (95% CI 0.276 to 1.868, p = 0.008), and the change score specification 0.727 (95% CI -0.139 to 1.592, p = 0.100). The two agree in direction but not magnitude, and the change score does not reach significance. Part of the analysis of covariance estimate is attributable to regression to the mean and to measurement error in the baseline term. We report both rather than selecting one.

Across horizons the estimate was inconsistent, from 1.072 at one year (p = 0.008, n = 698) to 2.104 at five (p = 0.091, n = 230), with censoring weights not restoring consistency. With attrition of this magnitude the horizon-specific estimates should not be over-interpreted.

Among seven baseline symptoms, pain and activities of daily living were the only two associated with the 12-month motor score after adjustment for the baseline motor score (Figure 6). Pain gave 0.933 points per baseline standard deviation (95% CI 0.240 to 1.626, p = 0.008), which survives Benjamini-Hochberg correction (p = 0.030) but not Holm (p = 0.051). Depression, anxiety, REM sleep behaviour, autonomic dysfunction and daytime sleepiness were all null. We pre-specified two negative-control outcomes at 12 months. Pain did not predict MoCA (-0.131, 95% CI -0.332 to 0.071, p = 0.204). It did predict GDS-15 (0.280, p = 0.004), more strongly and more significantly than it predicted the motor score. One control passed and one failed, and the one that failed is the more informative: whatever pain marks is at least as expressed in mood as in motor function.

The E-value for the 12-month estimate was 1.41, and 1.18 for the confidence limit. An unmeasured confounder of modest magnitude would suffice to explain it away.

### The association survives, but shrinks, under time-varying confounding

We pre-specified that the marginal structural model would be justified only if prior pain predicted current dose conditional on prior dose, and that otherwise standard regression would suffice and we would say so. That condition was **not** met: the coefficient was 18.3 mg (95% CI -2.2 to 38.9, p = 0.080). The reverse arm reached nominal significance (p = 0.031) at an effect of 0.014 pain points per 100 mg of levodopa equivalent, which is of no clinical consequence.

Both arms of the presumed feedback loop are therefore effectively null, the weights carry correspondingly little information, and by our own rule the marginal structural model is reported below as a **sensitivity analysis** rather than as a primary result.

Fitted on the same 1,970 observations from 787 patients (Figure 4), conventional regression gave 2.696 points for pain present versus absent (95% CI 1.428 to 3.964) unadjusted for dose and 2.612 (95% CI 1.336 to 3.887) adjusted for it. The marginal structural model gave 1.706 (95% CI 0.717 to 2.670 by patient resampling). A covariate-fixed substitution estimate gave 1.652; that quantity is not the g-formula, because a confounder affected by prior exposure must be simulated forward under each regime rather than held at its observed value, so we report it as descriptive and not as independent corroboration.

The weighted estimate is about 37% smaller than the conventional ones. We do not treat the substitution estimate as corroboration, for the reason given in Methods. Weighting improved balance on prior dose, with the standardised difference falling from 0.141 to 0.071, and the weights were well behaved (mean 0.999, range 0.75 to 1.39).

The association therefore persists under formal handling of time-varying confounding, but conventional regression overstates it by more than a third.

### The motor phenotype does not modify the association

Pain was more common in the postural instability and gait difficulty phenotype, with an adjusted ordinal odds ratio of 1.49 (95% CI 1.06 to 2.08, p = 0.022) relative to tremor dominance. This is consistent in direction with previous reports, though smaller in magnitude.^18^^19^

The phenotype did not modify the pain and motor severity association. The pre-specified interaction was -1.276 (p = 0.293). Across the 8 contrasts of postural instability and gait difficulty versus tremor dominance examined, 2 reached nominal significance, 0 survived Holm correction and 0 survived Benjamini-Hochberg. The two nominally significant contrasts had the opposite sign to the hypothesis, and neither reappeared when the classifying ratio was rebuilt from examiner-rated items alone (p = 0.655) or from patient-reported items alone (p = 0.564). Conclusions were unchanged across all three zero-denominator rules (p = 0.293, 0.264 and 0.252).

The phenotype was also not stable enough to be treated as a trait (Figure 5). Agreement with the baseline class fell from 74.0% at one year to 59.5% at five, with Cohen kappa falling from 0.443 to 0.227. The continuous ratio retained more order (Spearman 0.600 at one year, 0.375 at five) but also drifted.

Conditioning on the continuous phenotype axis attenuated the stable between-person association between pain and motor severity by 23.3% for the total motor score and 39.9% for the score excluding classifier items. The phenotype axis therefore accounts for part of the shared variation without accounting for all of it.

### The covariation is carried by specific motor domains and not by tremor

We decomposed the MDS-UPDRS Part III into five domains that sum exactly to the total. The between-person association with pain was present for every domain except tremor: bradykinesia 0.169 SD (p = <0.001), axial 0.187 (p = <0.001), rigidity 0.142 (p = <0.001), bulbar 0.141 (p = <0.001), and tremor 0.005 (95% CI -0.071 to 0.080, p = 0.905).

The contrast between the bradykinesia-rigidity axis and tremor, estimated within the same patients and the same instrument, was 0.172 (95% CI 0.073 to 0.271, p = 0.002). Because the comparison is internal to the scale, shared method variance cannot account for it. Fitting the random-intercept model separately by domain reproduced the two ends of the ordering, with the trait correlation highest for the axial domain (r = 0.253, p = 0.002) and null for tremor (r = 0.035, p = 0.578). It did not reproduce the middle: the bulbar domain fell from 0.141 to r = 0.013 (p = 0.831), below tremor. That is informative rather than incidental, since bulbar signs are the domain most likely to be carried by a general severity factor rather than by anything specific.

Two things bound what this can mean. Tremor is a weaker index of severity in general, correlating with disease duration at roughly a third the strength of the axial domain, which accounts for part but not all of a pain association about one fortieth as large.

Tremor depends on the cerebello-thalamo-cortical circuit in addition to the basal ganglia, and involves different mechanisms from bradykinesia and rigidity,^33^^34^ which would predict such a dissociation. More decisively, however, the dissociation is not specific to pain. Running the identical differential test with depression as the exposure gives 0.185 (95% CI 0.092 to 0.275, p = <0.001), indistinguishable from the 0.172 obtained for pain. The tremor dissociation is therefore a property of how non-motor burden relates to the motor scale, not a signature of anything specific to pain, and we do not interpret it as one.

### The covariation is independent of striatal dopaminergic loss

Motor severity tracked dopamine transporter binding as expected: -0.219 SD per SD of striatal binding (95% CI -0.285 to -0.153, p = <0.001), with equivalent results for putamen and caudate. Pain did not: 0.011 (95% CI -0.060 to 0.081, p = 0.766).

Adding striatal binding to the model left the pain and motor association unchanged, from 0.188 to 0.190 SD. Whatever links the two is therefore not the nigrostriatal dopaminergic axis that defines the motor syndrome. Prior analyses of this cohort have related broad panels of non-motor symptoms to striatal binding without including a pain measure.^35^^36^ We fill that gap. The null we report is therefore not a general property of non-motor measures in this cohort, and it is a new test rather than a replication. A smaller study reported that caudate binding specifically determined musculoskeletal pain.^12^ That is a regional test and ours is of mean striatal binding, so the two are not equivalent, and we do not present ours as a non-replication. Two limits apply to the inference. Binding indexes presynaptic terminal density, which is not the mechanism by which dopamine modulates pain: levodopa raises the objective nociceptive flexion reflex threshold^8^ and normalises thermal thresholds and pain-induced activation on positron emission tomography.^7^ A null association with binding is therefore compatible with substantial dopaminergic modulation of pain, and we do not claim otherwise.

### A single general factor accounts for the covariation

A one-factor model over the five motor domains, pain and MoCA fitted the data well. Loadings were 0.808 for bradykinesia, 0.706 for rigidity, 0.669 for bulbar, 0.602 for axial, 0.225 for pain, -0.212 for MoCA, and 0.042 for tremor, which did not load.

Model fit was acceptable by approximate indices (802 patients; CFI 0.959, RMSEA 0.061, SRMR 0.036) although the exact test rejected (chi-square 60.1 on 14 degrees of freedom).

Freeing the residual covariances between pain and the three motor domains did not improve fit (chi-square difference 4.34 on 3 degrees of freedom, p = 0.227), and no standardised residual for those cells exceeded conventional thresholds. The general factor therefore accounts for the pain and motor covariation, and no specific association remains once it is removed.

We note that an earlier version of this analysis obtained a significant negative residual by regressing indicators on factor scores computed from those same indicators. That procedure induces negative residual correlation by construction and its result should be disregarded; the nested test reported here is the correct one.

### Pain is the least trait-like of the measures examined

The intraclass correlation was 0.392 for pain, against 0.535 for the motor score, 0.595 for MoCA and 0.626 for depression. Only about 0.392 of the variance in pain lies between patients.

This bears directly on the null within-person paths. A measure with little stable between-person variance and correspondingly more within-person variation and measurement error offers less signal for a cross-lagged path to detect, and averaging over six waves improves the reliability of the between-person component but not of the within-person deviations. The null within-person paths are therefore consistent with a genuine absence of within-person coupling and with insufficient reliability to detect it, and we cannot distinguish these.

### The covariation is not demonstrably specific to Parkinson disease

We fitted the identical model simultaneously in all three cohorts as a multi-group structural equation model, defining the trait correlation as a derived parameter in each group so that its standard error comes from the model rather than from a formula for observed correlations. The estimates were 0.159 (95% CI 0.023 to 0.295) in patients, 0.213 (0.097 to 0.328) in 1,744 prodromal participants and 0.143 (-0.024 to 0.309) in 307 healthy controls.

The patient minus control difference was 0.016 (95% CI -0.199 to 0.231, p = 0.885), and a joint Wald test of equality across the three cohorts did not reject (chi-square 0.59 on 2 degrees of freedom, p = 0.744).

This comparison is not conclusive in either direction: with 307 controls the interval is compatible both with no correlation and with a correlation larger than in patients. What can be said is that the point estimate in controls is close to the patient estimate, which is not what a disease-specific substrate predicts, and that it was obtained despite a motor score standard deviation of 3.10 against 11.64 in patients, so range restriction works against rather than for the deflationary reading.

Modification by cerebrospinal fluid alpha-synuclein seed amplification status and by GBA carrier status was null, and both tests were underpowered. The association was no larger for lower-limb than for upper-limb motor items (0.185 vs 0.147 SD, difference p = 0.184), which does not support a predominantly peripheral mechanism.

### Analgesic use, sex, and motor complications

Analgesic use was measured because it is the obvious candidate for the modest unmeasured confounder our E-value describes. It is not, however, a confounder. Patients take analgesics because they have pain, so analgesic use is a descendant of the exposure, and conditioning on it does two unwanted things at once: it blocks the part of the association that runs through treatment, and it opens a collider path from pain to analgesic to any unmeasured painful comorbidity that also degrades motor performance. Adjusting for it therefore attenuates the estimate whether or not confounding is present, and the adjusted value is a lower bound rather than a decontaminated one.

We report it because a fully attenuated estimate would have been informative and it was not. Classifying the concomitant medication log by anchored drug-name patterns, and excluding aspirin because at low dose it is taken for cardioprotection rather than pain, 22.4% of the analytic sample was exposed at some point during follow-up (34.2% including aspirin, 1.7% for opioids). Conditioning on it moved the association from 0.173 to 0.157 SD (95% CI 0.076 to 0.238, p = <0.001), an attenuation of 9%, and the same held for any analgesic and for opioids alone.

The confounder the E-value describes is the underlying painful comorbidity, not its treatment, and that variable is not in this dataset.

The association was about twice as large in women (0.263 SD, n = 275, p = <0.001) as in men (0.115, n = 519, p = 0.013), although the interaction term did not reach significance (p = 0.100) and the stratum intervals overlap. The strata differ in the direction the literature predicts, and we report that without interpreting it, on the same standard we applied to the within-person path.

We raised in Methods the concern that a one-week pain recall spans on and off periods once motor complications begin. Adjusting for MDS-UPDRS Part IV attenuated the association from 0.200 to 0.159 SD (p = <0.001), and it was present both in patients without motor complications (0.198) and in those with them (0.149). The caveat is real and partial, not disqualifying.

### Pain does not stand out among non-motor symptoms

If the covariation reflects a general burden dimension rather than anything about pain, other items of the same questionnaire should behave similarly. Fitting the identical model with each of them as the exposure gave trait correlations with motor severity of 0.159 for pain (p = 0.026), 0.147 for fatigue (p = 0.032), 0.207 for daytime sleepiness (p = 0.008) and 0.277 for insomnia (p = <0.001).

Pain is not the largest of these. Insomnia exceeds it, and all four are of the same order. Pain trajectories in Parkinson disease are also known to fluctuate rather than track motor progression,^37^^38^ which is what a burden indicator rather than a motor correlate would do. A larger cross-sectional survey reached a similar conclusion, finding negligible correlation between motor impairment and musculoskeletal or dystonic pain and identifying affective and autonomic symptoms as the stronger correlates.^39^ Together with the failed depression control, the depression differential matching the pain differential, the single general factor that leaves no residual association, and the correlation of similar magnitude in prodromal participants and healthy controls, this is the fifth of five converging analyses pointing the same way. A contrary literature exists and we do not dismiss it: central parkinsonian pain has been described as a distinct phenotype with its own dopaminergic responsiveness,^40^ which would not be visible in a single undifferentiated item. Two of them, the cohort comparison and the phenotype interaction, are underpowered non-rejections rather than positive evidence, and the failed depression control and the depression differential share a measure and are not independent of each other. We therefore do not present the covariation as specific to pain, while noting that the convergence is stronger than any single test in it.

### The reporting-style explanation is testable, and it does not hold for the examined outcome

A stable individual tendency to report symptoms would produce a between-person correlation between pain and any other self-reported measure without any shared biology. Rather than concede this, we measured it. For each patient we took the residual of the patient-reported motor scale on the examined one, averaged over visits: a positive value marks someone who reports more disability than the examination finds. The index is stable across a year (r = 0.663) and does not use the pain item.

The confound is real. The index is strongly associated with pain (0.419 SD, 95% CI 0.348 to 0.489, p = <0.001), so a substantial part of what the pain item measures is reporting tendency rather than nociception.

It does not, however, explain the association with the examined motor score. Adjusting for the index left that association at 0.224 SD (p = <0.001), slightly larger than the unadjusted 0.173, which is what suppression by a correlate of the exposure that is unrelated to the outcome produces. It did explain most of the association with the patient-reported motor scale, which fell from 0.448 to 0.104, an attenuation of 77%.

Because that index is constructed as a residual on the examined score, it is orthogonal to it by construction, and a reader is entitled to discount the first half of that contrast. We therefore repeated it with an index that carries no such property: the summed remaining non-motor items of the same questionnaire, which share the pain item's method and perspective and are defined with no reference to anything motor. The pattern held. The association with the examined score attenuated 17%, from 0.173 to 0.144 (p = 0.002), while the association with the patient-reported scale attenuated 38%.

This resolves the question the previous section left open. The threefold larger correlation obtained with patient-reported motor function is largely shared method variance. The smaller correlation with the examined score is not, and survives both operationalisations.

---

## Discussion

In a cohort of recently diagnosed patients followed annually for five years, pain and motor severity covaried as stable characteristics of the patient, and neither preceded the other. Pain marked a persistently higher level of motor impairment rather than a faster rate of progression, and the association was small enough to fall below the threshold for a clinically perceptible difference.

The direction of that relationship depended entirely on how it was estimated. Fitted to the same six waves from the same 1,174 patients, a conventional cross-lagged panel model made both directions significant and would have supported reciprocal causation between pain and motor severity. A model that separates stable between-person differences from within-person change fits substantially better (0.963 vs 0.877 on CFI, 0.044 vs 0.112 on SRMR) and supports neither. Since the conventional model is the one this literature uses when it assigns a direction, that matters beyond this cohort.

The same pattern recurred in the other estimators we examined. Conventional regression overstated the contemporaneous association by about 37% relative to weighted estimation. A previously reported directional asymmetry in this cohort dissolved once both directions were fitted on the same participants rather than on each direction's own maximal set (0.116 on the common panel of 698). And a residual correlation we initially computed by regressing indicators on factor scores that contained them proved to be an artefact of that procedure: the correct nested test shows the general factor accounts for the covariation (0.227).

What survives is modest, and five converging analyses agree that it is not specific to pain: the depression negative control that fails, the depression differential that matches the pain differential, a single general factor that leaves no residual pain and motor association, a correlation in people without the disease that the data cannot distinguish from the patient estimate, and other non-motor items of the same questionnaire that covary with motor severity as strongly as pain does or more. We treat the general-burden reading as what the data support, not as an alternative we failed to exclude.

The practical implication is that pain in early Parkinson disease is better read as a marker of where a patient sits than as a signal of where they are heading. It identifies patients with more motor impairment at every point in follow-up, but it does not identify patients who will deteriorate faster, and the difference it marks is well below the threshold for a clinically perceptible one.

### Why the phenotype hypothesis failed

We predicted that pain would concentrate in the akinetic-rigid presentation and that its association with motor severity would be stronger there. The first half held; the second did not.

Two features of the classification bear on this. First, the phenotype is not the stable trait the hypothesis requires. Agreement with the baseline class fell to under two thirds by year 5, consistent with independent reports that most baseline tremor dominant patients do not remain so^41^^42^. A construct that reclassifies a third of patients within a year cannot carry a claim about stable mechanism. Second, and relatedly, the classifier is partly a running index of severity rather than a description of type: drift is driven by accumulating gait and balance scores, which are also the outcome.

That second point is the strongest competing explanation for our central finding,  If axial and non-dopaminergic burden increases with disease severity, and pain also increases with it, then the stable covariation we observe reflects a shared severity dimension rather than any specific link between nociception and motor control. That is what we now think the data show. Consistent with it, conditioning on the continuous phenotype axis removed a substantial share of the covariation but not all of it, and subtype drift in other cohorts is itself driven by accumulating gait and balance scores,^41^ and the same drift is visible here, with the postural instability group rising from 19.2% at baseline to 29.7% at year 5.

### The effect is below the threshold for clinical relevance

The minimal clinically important difference for worsening on MDS-UPDRS Part III is 4.63 points.^43^ Our level effect is 1.396 points per point of pain. Across the full 0 to 4 range of the item that reaches 5.58 points, which exceeds the threshold; the per-point contrast and the dichotomous weighted estimate (1.706) do not, the latter being roughly a third of it. The comparison that matters clinically is the per-point one, because moving a patient across the entire range of the item is not an intervention anyone can perform, but we report the full-range figure rather than rounding it down. The trait correlation of 0.152 corresponds to about 2% of shared variance.

The comparison is not exact, because that threshold anchors within-patient change and our estimate is a between-person level contrast. The mismatch does not rescue the magnitude. Nothing in these results should change how any individual patient is assessed or treated, and we state that plainly rather than leaving readers to infer it.

### Strengths

The cohort is large, recently diagnosed, initially untreated, and followed annually with a standardised motor examination in a defined medication state. Exposure and outcome do not share measurement method: pain is patient-reported and the motor examination is rated by a clinician, so shared-method correlation cannot explain the association. Exclusion for deep brain stimulation was applied without conditioning on the future, which matters because the naive approach removes precisely the patients who progress most. Attrition and time-varying confounding were handled explicitly rather than acknowledged in passing, the full inventory of hypothesis tests is declared and classified rather than left implicit, and each analysis that produced a result we favoured was subjected to a documented attempt at refutation before being accepted.

### The window this design can see

Pain does precede Parkinson disease at a longer timescale than we observe. In a population cohort of 33,388 adults, baseline pain predicted incident Parkinson disease with a dose-response gradient,^44^ and non-motor symptoms including pain are dated to before motor onset.^45^ Our claim is bounded accordingly: it concerns the interval after diagnosis, at annual resolution, and says nothing about the prodromal window.

### Limitations

A reporting-style confound is the most serious alternative explanation, and it is well documented in this cohort: participants who report more symptoms are equally or less impaired on examination and on biomarkers.^46^ We tested it rather than conceding it. The confound is real and large for the pain item, but it accounts for most of the association with patient-reported motor function and little of the association with the examined score, under two different operationalisations. What it does not rule out is a reporting tendency that tracks genuine examined severity, which no index built from self-report can separate.

The within-person reliability of the exposure is the second most important threat. Only 0.392 of the variance in pain lies between patients, against 0.535 for the motor score. Averaging over six waves improves the reliability of the between-person component but not of the within-person deviations, so the null within-person paths are consistent both with a genuine absence of coupling and with insufficient signal to detect it. We report this rather than resolve it, and the title says detectable for that reason.

The exposure is a single ordinal item that averages pain of different mechanisms. A validated Parkinson-specific pain instrument^20^ would allow the question to be asked of each subtype, and might well give different answers for musculoskeletal, dystonic and central pain. This is the single most important limitation.

Attrition is severe, and although censoring weights were close to one and did not move the estimates, weighting can only correct for measured predictors of dropout. Horizon-specific estimates beyond the first year rest on progressively smaller and more selected samples and should not be read individually.

The E-value of 1.41 indicates that an unmeasured confounder of modest strength would suffice to explain away the 12-month association. We could not measure it. Analgesic use, the obvious proxy, is a consequence of pain rather than a common cause and cannot serve that role, as explained in Results. Painful comorbidity itself, which is the variable the E-value describes, is not recorded in this dataset.

The causal estimand requires care. Pain is a state, not an intervention. "The effect of having pain" does not define a counterfactual without specifying how one would intervene, whether by analgesia, by treating dystonia or by adjusting dopaminergic control, and each of those would have a different effect. What the marginal structural model estimates is a weighted contrast under an explicit causal structure, not the effect of an assignable treatment.

Finally, the analysis was reframed after the results were known. The evidence and reasoning behind that change are documented, and readers can reconstruct and disagree with the decision, but it remains a change made after seeing the data.

### Conclusions

In early Parkinson disease, pain and motor severity coexist as stable characteristics of the patient. Neither precedes the other on the annual timescale this cohort can resolve, and pain marks the level of motor impairment rather than its rate of change. Analyses that do not separate stable between-person differences from within-person change will tend to find reciprocal causation where none is demonstrable.

---

## Data and code availability

Data are available from the Parkinson's Progression Markers Initiative^47^^48^ under its data use agreement and are not redistributed here. All analysis code, the enrolment flow, the exported numerical results and the dated decision records are available in the accompanying public repository. Continuous integration verifies at every change that no participant-level data are committed.

---

## References

1. Rotnitzky A, Robins J. Analysis of semi-parametric regression models with non-ignorable non-response. Statistics in Medicine. 1997;16(1-3):81-102. PMID: 9004385. doi:10.1002/(sici)1097-0258(19970115)16:1<81::aid-sim473>3.0.co;2-0.

2. Defazio G, Berardelli A, Fabbrini G et al. Pain as a nonmotor symptom of Parkinson disease: evidence from a case-control study. Arch Neurol. 2008;65(9):1191-4. PMID: 18779422. doi:10.1001/archneurol.2008.2.

3. Nègre-Pagès L, Regragui W, Bouhassira D et al. Chronic pain in Parkinson's disease: the cross-sectional French DoPaMiP survey. Mov Disord. 2008;23(10):1361-9. PMID: 18546344. doi:10.1002/mds.22142.

4. Tinazzi M, Gandolfi M, Artusi CA et al. Advances in diagnosis, classification, and management of pain in Parkinson's disease. Lancet Neurol. 2025;24(4):331-347. PMID: 40120617. doi:10.1016/S1474-4422(25)00033-X.

5. Belasen A; Youn Y; Gee L; Prusik J; Lai B; Ramirez-Zamora A; Rizvi K; Yeung P; Shin DS; Argoff C; Pilitsis JG. The effects of mechanical and thermal stimuli on local field potentials and single unit activity in Parkinson's disease patients. Neuromodulation. 2016;19:698-707. PMID: 27284636. doi:10.1111/ner.12453.

6. Charles KA; Molpeceres Sierra E; Bouali-Benazzouz R; Tibar H; Oudaha K; Naudet F; Duveau A; Fossat P; Benazzouz A. Interplay between subthalamic nucleus and spinal cord controls parkinsonian nociceptive disorders. Brain. 2025;148:313-330. PMID: 38916480. doi:10.1093/brain/awae200.

7. Brefel-Courbon C, Payoux P, Thalamas C et al. Effect of levodopa on pain threshold in Parkinson's disease: a clinical and positron emission tomography study. Mov Disord. 2005;20(12):1557-63. PMID: 16078219. doi:10.1002/mds.20629.

8. Gerdelat-Mas A; Simonetta-Moreau M; Thalamas C; Ory-Magne F; Slaoui T; Rascol O; Brefel-Courbon C. Levodopa raises objective pain threshold in Parkinson's disease: a RIII reflex study. Journal of Neurology, Neurosurgery, and Psychiatry. 2007;78:1140-1142. PMID: 17504881. doi:10.1136/jnnp.2007.120212.

9. Pautrat A; Al Tannir R; Pernet-Gallay K; Soutrenon R; Vendramini E; Sinniger V; Overton PG; David O; Coizet V. Altered parabrachial nucleus nociceptive processing may underlie central pain in Parkinson's disease. npj Parkinsons Disease. 2023;9:78. PMID: 37236965. doi:10.1038/s41531-023-00516-x.

10. Rukavina K, Staunton J, Zinzalias P, et al. Pain in Parkinson's disease is impacted by motor complications, anxiety and sleep disturbances. European Journal of Pain. 2025;29(2):e4765. PMID: 40470722. doi:10.1002/ejp.4765.

11. Schrag A, Horsfall L, Walters K et al. Prediagnostic presentations of Parkinson's disease in primary care: a case-control study. Lancet Neurol. 2015;14(1):57-64. PMID: 25435387. doi:10.1016/S1474-4422(14)70287-X.

12. Rukavina K, Mulholland N, Corcoran B et al. Musculoskeletal pain in Parkinson's disease: Association with dopaminergic deficiency in the caudate nucleus. Eur J Pain. 2024;28(2):244-251. PMID: 37587725. doi:10.1002/ejp.2172.

13. Hamaker EL; Kuiper RM; Grasman RP. A critique of the cross-lagged panel model. Psychological Methods. 2015;20:102-116. PMID: 25822208. doi:10.1037/a0038889.

14. Hodgson P, Jordan A, Sinani C et al. Longitudinal Dynamics of Physical Function With Anxiety and Depression in Parkinson's Disease: A Cross-Lagged Panel Analysis of the PPMI Dataset. Brain Behav. 2026;16(2):e71257. PMID: 41677352. doi:10.1002/brb3.71257.

15. Schroeders U, Zimmermann J, Wicke T et al. Dynamic interplay of cognitive functioning and depressive symptoms in patients with Parkinson's disease. Neuropsychology. 2022;36(4):266-278. PMID: 35175065. doi:10.1037/neu0000795.

16. Robins JM, Hernan MA, Brumback B. Marginal structural models and causal inference in epidemiology. Epidemiology. 2000;11(5):550-560. PMID: 10955408. doi:10.1097/00001648-200009000-00011.

17. Hernan MA, Brumback B, Robins JM. Marginal structural models to estimate the causal effect of zidovudine on the survival of HIV-positive men. Epidemiology. 2000;11(5):561-570. PMID: 10955409. doi:10.1097/00001648-200009000-00012.

18. Ren J, Hua P, Pan C, et al. Non-Motor Symptoms of the Postural Instability and Gait Difficulty Subtype in De Novo Parkinson's Disease Patients: A Cross-Sectional Study in a Single Center. Neuropsychiatric Disease and Treatment. 2020;16:2605-2612. PMID: 33173298. doi:10.2147/NDT.S280960.

19. Rodriguez-Violante M, Alvarado-Bolanos A, Cervantes-Arriaga A, et al. Clinical Determinants of Parkinson's Disease-associated Pain Using the King's Parkinson's Disease Pain Scale. Movement Disorders Clinical Practice. 2017;4(4):545-551. PMID: 30363423. doi:10.1002/mdc3.12469.

20. Mylius V, Perez Lloret S, Cury RG et al. The Parkinson disease pain classification system: results from an international mechanism-based classification approach. Pain. 2021;162(4):1201-1210. PMID: 33044395. doi:10.1097/j.pain.0000000000002107.

21. Gallagher DA, Goetz CG, Stebbins G et al. Validation of the MDS-UPDRS Part I for nonmotor symptoms in Parkinson's disease. Mov Disord. 2012;27(1):79-83. PMID: 21915909. doi:10.1002/mds.23939.

22. Martinez-Martin P, Chaudhuri KR, Rojo-Abuin JM et al. Assessing the non-motor symptoms of Parkinson's disease: MDS-UPDRS and NMS Scale. Eur J Neurol. 2015;22(1):37-43. PMID: 23607783. doi:10.1111/ene.12165.

23. Simuni T, Caspell-Garcia C, Coffey CS, et al. Baseline prevalence and longitudinal evolution of non-motor symptoms in early Parkinson's disease: the PPMI cohort. Journal of Neurology, Neurosurgery and Psychiatry. 2018;89(1):78-88. PMID: 28986467. doi:10.1136/jnnp-2017-316213.

24. Goetz CG; Tilley BC; Shaftman SR; Stebbins GT; Fahn S; Martinez-Martin P; Poewe W; Sampaio C; Stern MB; Dodel R; Dubois B; Holloway R; Jankovic J; Kulisevsky J; Lang AE; Lees A; Leurgans S; LeWitt PA; Nyenhuis D; Olanow CW; Rascol O; Schrag A; Teresi JA; van Hilten JJ; LaPelle N. Movement Disorder Society-sponsored revision of the Unified Parkinson's Disease Rating Scale (MDS-UPDRS): scale presentation and clinimetric testing results. Movement Disorders. 2008;23:2129-2170. PMID: 19025984. doi:10.1002/mds.22340.

25. Stebbins GT, Goetz CG, Burn DJ, et al. How to identify tremor dominant and postural instability/gait difficulty groups with the movement disorder society unified Parkinson's disease rating scale: comparison with the unified Parkinson's disease rating scale. Movement Disorders. 2013;28(5):668-670. PMID: 23408503. doi:10.1002/mds.25383.

26. Curran PJ, Howard AL, Bainter SA, Lane ST, McGinley JS. The separation of between-person and within-person components of individual change over time: a latent curve model with structured residuals. Journal of Consulting and Clinical Psychology. 2014;82(5):879-894. PMID: 24364798. doi:10.1037/a0035297.

27. Glymour MM, Weuve J, Berkman LF, et al. When is baseline adjustment useful in analyses of change? An example with education and cognitive change. American Journal of Epidemiology. 2005;162(3):267-278. PMID: 15987729. doi:10.1093/aje/kwi187.

28. Senn S. Change from baseline and analysis of covariance revisited. Statistics in Medicine. 2006;25(24):4334-4344. PMID: 16921578. doi:10.1002/sim.2682.

29. Arah OA. The role of causal reasoning in understanding Simpson's paradox, Lord's paradox, and the suppression effect: covariate selection in the analysis of observational studies. Emerging Themes in Epidemiology. 2008;5:5. PMID: 18302750. doi:10.1186/1742-7622-5-5.

30. Hernan MA, Brumback BA, Robins JM. Estimating the causal effect of zidovudine on CD4 count with a marginal structural model for repeated measures. Statistics in Medicine. 2002;21(12):1689-1709. PMID: 12111906. doi:10.1002/sim.1144.

31. VanderWeele TJ, Ding P. Sensitivity Analysis in Observational Research: Introducing the E-Value. Annals of Internal Medicine. 2017;167(4):268-274. PMID: 28693043. doi:10.7326/M16-2607.

32. VanderWeele TJ, Mathur MB, Ding P. Correcting Misinterpretations of the E-Value. Annals of Internal Medicine. 2019;170(2):131-132. PMID: 30597489. doi:10.7326/M18-3112.

33. Helmich RC, Hallett M, Deuschl G et al. Cerebral causes and consequences of parkinsonian resting tremor: a tale of two circuits?. Brain. 2012;135(Pt 11):3206-26. PMID: 22382359. doi:10.1093/brain/aws023.

34. Helmich RC. The cerebral basis of Parkinsonian tremor: A network perspective. Mov Disord. 2018;33(2):219-231. PMID: 29119634. doi:10.1002/mds.27224.

35. Liu R, Umbach DM, Tröster AI et al. Non-motor symptoms and striatal dopamine transporter binding in early Parkinson's disease. Parkinsonism Relat Disord. 2020;72:23-30. PMID: 32092703. doi:10.1016/j.parkreldis.2020.02.001.

36. Yang Z, Xie Y, Dou K et al. Associations of striatal dopamine transporter binding with motor and non-motor symptoms in early Parkinson's disease. Clin Transl Sci. 2023;16(6):1021-1038. PMID: 36915231. doi:10.1111/cts.13508.

37. Gunzler DD, Gunzler SA, Briggs FBS. Heterogeneous pain trajectories in persons with Parkinson's disease. Parkinsonism Relat Disord. 2022;102:42-50. PMID: 35933822. doi:10.1016/j.parkreldis.2022.07.006.

38. Naisby J, Lawson RA, Galna B et al. Trajectories of pain over 6 years in early Parkinson's disease: ICICLE-PD. J Neurol. 2021;268(12):4759-4767. PMID: 33991240. doi:10.1007/s00415-021-10586-7.

39. Silverdale MA, Kobylecki C, Kass-Iliyya L et al. A detailed clinical study of pain in 1957 participants with early/moderate Parkinson's disease. Parkinsonism Relat Disord. 2018;56:27-32. PMID: 29903584. doi:10.1016/j.parkreldis.2018.06.001.

40. Vila-Chã N, Cavaco S, Mendes A et al. Unveiling the relationship between central parkinsonian pain and motor symptoms in Parkinson's disease. Eur J Pain. 2019;23(8):1475-1485. PMID: 31070825. doi:10.1002/ejp.1413.

41. von Coelln R, Gruber-Baldini AL, Reich SG, et al. The inconsistency and instability of Parkinson's disease motor subtypes. Parkinsonism & Related Disorders. 2021;88:13-18. PMID: 34091412. doi:10.1016/j.parkreldis.2021.05.016.

42. Kohat AK, Ng SYE, Wong ASY, et al. Stability of MDS-UPDRS Motor Subtypes Over Three Years in Early Parkinson's Disease. Frontiers in Neurology. 2021;12:704906. PMID: 34630281. doi:10.3389/fneur.2021.704906.

43. Horvath K, Aschermann Z, Acs P, et al. Minimal clinically important difference on the Motor Examination part of MDS-UPDRS. Parkinsonism & Related Disorders. 2015;21(12):1421-1426. PMID: 26578041. doi:10.1016/j.parkreldis.2015.10.006.

44. Lin CH, Wu RM, Chang HY et al. Preceding pain symptoms and Parkinson's disease: a nationwide population-based cohort study. Eur J Neurol. 2013;20(10):1398-404. PMID: 23679105. doi:10.1111/ene.12197.

45. Pont-Sunyer C, Hotter A, Gaig C et al. The onset of nonmotor symptoms in Parkinson's disease (the ONSET PD study). Mov Disord. 2015;30(2):229-37. PMID: 25449044. doi:10.1002/mds.26077.

46. Zolfaghari S, Thomann AE, Lewandowski N et al. Self-Report versus Clinician Examination in Early Parkinson's Disease. Mov Disord. 2022;37(3):585-597. PMID: 34897818. doi:10.1002/mds.28884.

47. Parkinson Progression Marker Initiative. The Parkinson Progression Marker Initiative (PPMI). Prog Neurobiol. 2011;95(4):629-35. PMID: 21930184. doi:10.1016/j.pneurobio.2011.09.005.

48. Marek K, Chowdhury S, Siderowf A et al. The Parkinson's progression markers initiative (PPMI) - establishing a PD biomarker cohort. Ann Clin Transl Neurol. 2018;5(12):1460-1477. PMID: 30564614. doi:10.1002/acn3.644.

