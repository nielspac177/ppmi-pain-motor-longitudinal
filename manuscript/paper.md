# Pain and motor severity in early Parkinson disease coexist without temporal precedence: a longitudinal analysis of the Parkinson's Progression Markers Initiative

## Abstract

**Importance.** Pain affects most people with Parkinson disease and is consistently associated with greater motor severity. Whether one precedes the other is unresolved, and nearly all published claims assert that motor severity drives pain. Cross-sectional designs cannot separate the two, and the longitudinal designs used so far cannot separate stable differences between patients from change within a patient.

**Objective.** To determine whether pain and motor severity are related by temporal precedence in either direction, or instead covary as stable characteristics of the patient, and to estimate the association under explicit handling of time-varying confounding by dopaminergic dose.

**Design, setting and participants.** Cohort study using six annual assessments (baseline through year 5) from the Parkinson's Progression Markers Initiative, a multicentre observational study of recently diagnosed Parkinson disease. {{n_baseline}} participants contributed a baseline assessment; {{n_v04}} formed the analytic sample at the 12-month visit.

**Exposures.** Pain, measured by MDS-UPDRS item 1.9, as a five-level ordinal score and dichotomised as present or absent.

**Main outcomes and measures.** MDS-UPDRS Part III, examined off medication or before treatment. The primary temporal analysis was a random-intercept cross-lagged panel model, which separates stable between-person differences from within-person change. Attrition was handled by inverse probability of censoring weighting, and dopaminergic dose by a marginal structural model with stabilised inverse probability of treatment weights, cross-checked by g-computation.

**Results.** Participants had a mean age of {{edad_media}} years (SD {{edad_de}}), {{pct_varones}} were male, and mean disease duration was {{duracion_media}} years. A conventional cross-lagged model made both directions significant (pain to motor p = {{clpm_dolor_motor_p}}; motor to pain p = {{clpm_motor_dolor_p}}). Separating stable between-person differences fit the data substantially better (CFI {{riclpm_cfi}} vs {{clpm_cfi}}; RMSEA {{riclpm_rmsea}} vs {{clpm_rmsea}}) and eliminated the motor-to-pain path (p = {{riclpm_motor_dolor_p}}). The remaining within-person pain-to-motor path (p = {{riclpm_dolor_motor_p}}) survived only {{refut_n_sig}} of {{refut_n_total}} robustness specifications and only {{refut_olas_sig}} of {{refut_olas_total}} waves, and is not claimed. What remained was a stable between-person correlation of the two series (r = {{rasgo_r}}, p = {{rasgo_p}}). Baseline pain was associated with a persistently higher motor score ({{mixto_nivel_est}} points per pain point, 95% CI {{mixto_nivel_ic}}, p = {{mixto_nivel_p}}) but not with a steeper slope (p = {{mixto_pendiente_p}}), and censoring weights did not change either conclusion. Under the marginal structural model the contemporaneous association was {{msm_iptw_est}} points (95% CI {{msm_boot_ic}}), about {{msm_reduccion}} smaller than conventional regression ({{msm_crudo_est}}, 95% CI {{msm_crudo_ic}}), with close agreement from g-computation ({{msm_gcomp_est}}, 95% CI {{msm_gcomp_ic}}). Pain was more common in the postural instability and gait difficulty phenotype (adjusted ordinal OR {{fen_or_pigd}}, 95% CI {{fen_or_pigd_ic}}, p = {{fen_or_pigd_p}}), but the phenotype did not modify the association (pre-specified interaction p = {{fen_interaccion_p}}; no contrast survived correction for multiplicity).

**Conclusions and relevance.** In early Parkinson disease, pain and motor severity covary as stable characteristics of the patient rather than one preceding the other. Pain marks a higher level of motor impairment, not a faster rate of progression. Claims of directionality in either direction are not supported once between-person and within-person variation are separated, which has implications for how the pain and motor relationship is modelled and interpreted.

---

## Introduction

Pain is among the most common non-motor features of Parkinson disease and is repeatedly found to accompany greater motor impairment. The mechanistic accounts proposed for this association are plausible and varied: basal ganglia participation in nociceptive processing, altered sensory gating, dopaminergic modulation of pain threshold, and non-dopaminergic degeneration involving structures implicated in pain at early Braak stages.

What these accounts share is an assumption about order. Almost without exception, the literature that assigns a direction assigns it from motor disease to pain: pain is treated as a consequence of rigidity, of dystonia, or of fluctuation in dopaminergic state. The reverse possibility, that pain marks or contributes to motor deterioration, has received much less attention, and the possibility that neither precedes the other has received almost none.

The reason this remains unsettled is methodological rather than substantive. Cross-sectional designs measure both quantities on the same day and cannot invoke temporal order. The longitudinal designs used so far, when they estimate lagged effects at all, use models that confound two different sources of variation. If patients differ stably in how much pain and how much motor impairment they carry, a conventional cross-lagged panel model will report significant paths in both directions purely from that stable covariation, without anyone ever moving in response to anyone else. Distinguishing "patients with more pain have more motor impairment" from "when a patient's pain rises, their motor score rises afterwards" requires a model that separates the two, and that separation has not been applied to this question.

A second complication is specific to Parkinson disease. Dopaminergic dose responds to symptoms and in turn affects both later symptoms and later dose. It is therefore a time-varying confounder affected by prior exposure, the canonical situation in which conventional regression is biased whether or not the confounder is adjusted for.

We used six annual assessments from a large cohort of recently diagnosed patients to address three questions. First, whether pain and motor severity are related by temporal precedence in either direction once stable between-person differences are separated from within-person change. Second, whether pain is associated with the level of motor impairment, its rate of progression, or both, with attrition modelled explicitly. Third, what the association becomes when dopaminergic dose is handled as a time-varying confounder rather than as an ordinary covariate.

We also tested a specific mechanistic prediction. If the association reflects shared pathophysiology rather than confounding, pain should concentrate in the akinetic-rigid presentation and its association with motor severity should be stronger there.

---

## Methods

Figure 1 summarises the analytic strategy: which question each estimator answers and what it produced.

### Study design and participants

We analysed data from the Parkinson's Progression Markers Initiative, an international multicentre observational cohort of recently diagnosed, initially untreated Parkinson disease. We used the baseline visit and the five subsequent annual visits.

Eligibility followed a frozen enrolment flow. Of {{flow_all_curated_rows}} records in the curated release, {{flow_at_visit}} corresponded to the 12-month visit, of which {{flow_pd_cohort}} were in the Parkinson disease cohort. We excluded participants with monogenic forms (LRRK2, SNCA, PRKN, PINK1), leaving {{flow_after_monogenic_exclusion}}; carriers of GBA variants were retained, since GBA is a risk variant rather than a deterministic monogenic form. We then excluded participants who had received deep brain stimulation on or before the visit date, leaving {{flow_after_dbs_exclusion}}.

Exclusion for deep brain stimulation was applied by comparing the date of the first recorded procedure with the visit date. Marking every participant who ever received stimulation, including years later, conditions on the future and systematically removes the patients who progress most, who are precisely the surgical candidates.

Complete pain data left {{flow_after_pain_complete}} participants and complete motor data left {{n_v04}}, the analytic sample at 12 months. Across all six visits, {{n_pacientes_panel}} participants contributed {{n_obs_panel}} assessments with both pain and motor data.

### Exposure

Pain was measured with item 1.9 of the MDS-UPDRS, a patient-reported five-level ordinal item. It was analysed both as an ordinal score from 0 to 4 and dichotomised as present (1 or above) versus absent. This item averages entities with different mechanisms, which we return to in the limitations.

### Outcome

The outcome was the MDS-UPDRS Part III total, examined off medication or before treatment initiation. The Parkinson's Progression Markers Initiative records up to two Part III examinations per visit; we verified that the curated off-state score corresponds to records with a practically defined off state or no recorded medication state, and used those records throughout so that exposure, phenotype and outcome refer to a single clinical state. The on-state score was used in sensitivity analyses.

Disease duration was recomputed at each visit as age at visit minus age at symptom onset. The duration variable distributed with the cohort is fixed at baseline and does not advance between visits, which would understate duration at follow-up by roughly two years.

### Motor phenotype

We classified the tremor dominant and postural instability and gait difficulty phenotypes using the ratio of Stebbins et al., defined as the mean of 11 tremor items divided by the mean of 5 postural instability and gait items, drawn from Parts II and III of the MDS-UPDRS. A ratio at or above 1.15 defines tremor dominance, at or below 0.90 defines postural instability and gait difficulty, and values in between are indeterminate.

In a recently diagnosed cohort a substantial minority has no axial signs at all, so the denominator is exactly zero and the ratio is undefined. This affected {{cero_denom_pct}} of the analytic sample at 12 months. We were unable to verify that the source article specifies a rule for this case, and a review of studies applying the criterion found none that states one. We therefore pre-specified the convention inherited from the earlier Jankovic ratio, in which a zero denominator with any tremor is classified as tremor dominant and a patient with neither is indeterminate, and we report two alternatives as sensitivity analyses: classifying all such cases as indeterminate, and excluding them.

Because the classifier and the outcome share items, we constructed a motor score excluding the 13 Part III items used for classification and repeated the phenotype analyses with it. We also rebuilt the ratio separately from examiner-rated Part III items and from patient-reported Part II items, to test whether any apparent effect modification was shared-method correlation.

### Statistical analysis

The adjustment set for all models was age, sex, disease duration and MoCA. Hoehn and Yahr stage was deliberately excluded: it is by construction a staging of motor function and therefore a coarse measurement of the outcome, so conditioning on it is overadjustment rather than confounding control.

**Temporal precedence.** We fitted a random-intercept cross-lagged panel model across the six waves, in which a random intercept per construct captures stable between-person differences and the cross-lagged paths are estimated on within-person deviations from each patient's own level. We fitted the conventional cross-lagged panel model for contrast. Both used full information maximum likelihood with a robust estimator. We tested the tenability of the across-wave equality constraints by likelihood ratio test and, since they were rejected, report the wave-specific paths.

**Robustness of the within-person path.** Any surviving cross-lagged path was subjected to seven checks: freeing the equality constraints, wave-specific estimation, restriction to the three earliest waves where attrition is least, addition of baseline auxiliary variables as saturated correlates, dichotomisation of the exposure, substitution of the on-state motor score, and a negative control substituting MoCA for the motor outcome.

**Level versus slope, and attrition.** We fitted a linear mixed model with random intercept and random slope, testing the interaction between baseline pain and elapsed time. Time was the actual interval from each patient's baseline computed from visit dates, not the nominal visit number. We modelled retention at each visit by logistic regression on baseline characteristics, and constructed stabilised inverse probability of censoring weights, truncated at the 1st and 99th percentiles. Every longitudinal result is reported weighted and unweighted. We report the analysis of covariance and the change score specifications side by side, since they answer different questions and Lord's paradox applies.

**Time-varying confounding.** We first verified empirically that dopaminergic dose behaves as a confounder affected by prior exposure, by testing whether prior pain predicts current dose conditional on prior dose, and whether prior dose predicts current pain conditional on prior pain. We then fitted a marginal structural model with stabilised inverse probability of treatment weights, accumulated multiplicatively over follow-up and truncated at the 1st and 99th percentiles, and assessed balance on prior dose. Confidence intervals were obtained by resampling whole patients with the weights re-estimated inside each replicate, because the sandwich estimator treats estimated weights as known and is anticonservative. We cross-checked with a g-computation substitution estimator, whose modelling assumptions differ.

**Effect modification.** We estimated the pain by phenotype interaction and the effect stratified by phenotype, with the phenotype classified at baseline and the outcome at 12 months to reduce circularity. The pre-specified primary specification was the full MDS-UPDRS Part III outcome, the ordinal exposure and the baseline phenotype. All other combinations were sensitivity analyses, and we report Holm and Benjamini-Hochberg corrections across the full grid.

**Sensitivity to unmeasured confounding.** E-values were computed on the standardised scale, using the standard deviation of the outcome, not on the raw coefficient.

Analyses used R 4.5.1. Reporting follows STROBE. The pre-specification, and every methodological decision that changed a result, is recorded in dated architecture decision records in the accompanying repository.

### Changes from the original plan

This study was planned to test whether pain predicts motor deterioration, with motor phenotype as the mechanism. Neither hypothesis was supported, and the question was reframed after the analyses were run. We state this explicitly rather than presenting the final framing as the original one. The reasoning and the evidence behind the change are recorded in the repository.

---

## Results

### Participants

At the 12-month visit the analytic sample comprised {{n_v04}} participants with a mean age of {{edad_media}} years (SD {{edad_de}}), of whom {{pct_varones}} were male, with mean disease duration of {{duracion_media}} years (SD {{duracion_de}}) and mean MDS-UPDRS Part III of {{updrs3_medio}} (SD {{updrs3_de}}). Pain was reported by {{pct_con_dolor}}. Median levodopa equivalent daily dose was {{ledd_mediana}} mg.

Retention fell from {{ret_n_BL}} participants at baseline to {{ret_n_V12}} at year 5 ({{ret_pct_V12}} of those with a baseline assessment; Figure 3). Baseline pain did not predict dropout at any horizon (smallest p = {{atricion_dolor_p_min}}). Baseline motor severity did, increasingly so with time (OR {{atricion_motor_v12_or}} per point at year 5, p = {{atricion_motor_v12_p}}). Attrition therefore depends on the outcome but not on the exposure. Stabilised censoring weights were close to one (means {{ipcw_media_min}} to {{ipcw_media_max}}; range {{ipcw_min}} to {{ipcw_max}}), which bounds how far attrition can have distorted the estimates.

### Neither direction precedes the other

The conventional cross-lagged panel model reproduced the pattern reported in earlier work on this cohort: both directions significant, with pain predicting later motor severity (p = {{clpm_dolor_motor_p}}) and motor severity predicting later pain (p = {{clpm_motor_dolor_p}}).

Separating stable between-person differences changed this (Figure 2). The random-intercept model fit substantially better (CFI {{riclpm_cfi}} vs {{clpm_cfi}}; RMSEA {{riclpm_rmsea}} vs {{clpm_rmsea}}; SRMR {{riclpm_srmr}} vs {{clpm_srmr}}). In it the motor-to-pain path was null (p = {{riclpm_motor_dolor_p}}). What the conventional model had been reading as reciprocal causation was a stable correlation between the two series across patients: r = {{rasgo_r}} (p = {{rasgo_p}}).

A within-person pain-to-motor path remained (p = {{riclpm_dolor_motor_p}}), and we do not claim it. The across-wave equality constraints that produce it were rejected (p = {{refut_lrt_p}}), and when the paths were freed only {{refut_olas_sig}} of {{refut_olas_total}} waves reached significance, the first. Across the six robustness specifications the path survived {{refut_n_sig}}: it disappeared when the exposure was dichotomised, when the on-state motor score was used, and when analysis was restricted to the three earliest waves. The negative control behaved as intended, with no path from pain to later MoCA.

Two conclusions follow. Reciprocal causation between pain and motor severity is not supported. Neither is precedence in either direction.

We also examined why an earlier analysis of this cohort had found asymmetry over the baseline to 12-month window. The two directions had been estimated on different sets of participants, because pain is recorded for more people than the motor examination. On the common complete panel the motor-to-pain path gives p = {{ventana_motor_dolor_p}}; using each direction's own maximal set it gives a different answer at the conventional threshold. The point estimates are positive either way. The asymmetry was an artefact of the analysis set, not a temporal fact.

### Pain marks a level, not a rate of progression

Baseline pain was associated with a persistently higher motor score across follow-up: {{mixto_nivel_est}} points of MDS-UPDRS Part III per point of pain (95% CI {{mixto_nivel_ic}}, p = {{mixto_nivel_p}}). The interaction with time was null ({{mixto_pendiente_est}}, 95% CI {{mixto_pendiente_ic}}, p = {{mixto_pendiente_p}}). Weighting for censoring left both unchanged (level {{mixto_w_nivel_est}}, p = {{mixto_w_nivel_p}}; slope p = {{mixto_w_pendiente_p}}; Figure 3).

Pain therefore marks a higher level of motor impairment, not a faster rate of deterioration.

The analysis of covariance over the first year gave {{ancova_est}} points (95% CI {{ancova_ic}}, p = {{ancova_p}}), and the change score specification {{cambio_est}} (95% CI {{cambio_ic}}, p = {{cambio_p}}). The two agree in direction but not magnitude, and the change score does not reach significance. Part of the analysis of covariance estimate is attributable to regression to the mean and to measurement error in the baseline term. We report both rather than selecting one.

Across horizons the estimate was inconsistent, from {{hor_V04_est}} at one year (p = {{hor_V04_p}}, n = {{hor_V04_n}}) to {{hor_V12_est}} at five (p = {{hor_V12_p}}, n = {{hor_V12_n}}), with censoring weights not restoring consistency. With attrition of this magnitude the horizon-specific estimates should not be over-interpreted.

Among seven baseline symptoms, pain and activities of daily living were the only two associated with the 12-month motor score after adjustment for the baseline motor score (Figure 6). Pain gave {{disc_dolor_est}} points per baseline standard deviation (95% CI {{disc_dolor_ic}}, p = {{disc_dolor_p}}), which survives Benjamini-Hochberg correction (p = {{disc_dolor_bh}}) but not Holm (p = {{disc_dolor_holm}}). Depression, anxiety, REM sleep behaviour, autonomic dysfunction and daytime sleepiness were all null. Pain did not predict the 12-month MoCA ({{ctrl_moca_est}}, 95% CI {{ctrl_moca_ic}}, p = {{ctrl_moca_p}}).

The E-value for the 12-month estimate was {{evalue_puntual}}, and {{evalue_ic}} for the confidence limit. An unmeasured confounder of modest magnitude would suffice to explain it away.

### The association survives, but shrinks, under time-varying confounding

Dopaminergic dose behaved as predicted for a confounder affected by prior exposure. Prior pain predicted current dose conditional on prior dose ({{ledd_dolor_est}} mg, 95% CI {{ledd_dolor_ic}}, p = {{ledd_dolor_p}}), and prior dose predicted current pain conditional on prior pain (p = {{dolor_ledd_p}}). The feedback is weak but present in both directions.

Fitted on the same {{msm_n_obs}} observations from {{msm_n_pac}} patients (Figure 4), conventional regression gave {{msm_crudo_est}} points for pain present versus absent (95% CI {{msm_crudo_ic}}) unadjusted for dose and {{msm_ajustado_est}} (95% CI {{msm_ajustado_ic}}) adjusted for it. The marginal structural model gave {{msm_iptw_est}} (95% CI {{msm_boot_ic}} by patient resampling), and g-computation {{msm_gcomp_est}} (95% CI {{msm_gcomp_ic}}).

The two causal estimators agree closely despite different modelling assumptions, and both are about {{msm_reduccion}} smaller than the conventional estimates. Weighting improved balance on prior dose, with the standardised difference falling from {{balance_sin}} to {{balance_con}}, and the weights were well behaved (mean {{iptw_media}}, range {{iptw_min}} to {{iptw_max}}).

The association therefore persists under formal handling of time-varying confounding, but conventional regression overstates it by more than a third.

### The motor phenotype does not modify the association

Pain was more common and more severe in the postural instability and gait difficulty phenotype, with an adjusted ordinal odds ratio of {{fen_or_pigd}} (95% CI {{fen_or_pigd_ic}}, p = {{fen_or_pigd_p}}) relative to tremor dominance. This is consistent in direction with previous reports, though smaller in magnitude.

The phenotype did not modify the pain and motor severity association. The pre-specified interaction was {{fen_interaccion_est}} (p = {{fen_interaccion_p}}). Across the {{fen_contrastes_total}} contrasts of postural instability and gait difficulty versus tremor dominance examined, {{fen_contrastes_sig}} reached nominal significance, {{fen_contrastes_holm}} survived Holm correction and {{fen_contrastes_bh}} survived Benjamini-Hochberg. The two nominally significant contrasts had the opposite sign to the hypothesis, and neither reappeared when the classifying ratio was rebuilt from examiner-rated items alone (p = {{fen_metodo_p3_p}}) or from patient-reported items alone (p = {{fen_metodo_p2_p}}). Conclusions were unchanged across all three zero-denominator rules (p = {{cero_jankovic_p}}, {{cero_indet_p}} and {{cero_excl_p}}).

The phenotype was also not stable enough to be treated as a trait (Figure 5). Agreement with the baseline class fell from {{fen_concord_v04}} at one year to {{fen_concord_v12}} at five, with Cohen kappa falling from {{fen_kappa_v04}} to {{fen_kappa_v12}}. The continuous ratio retained more order (Spearman {{fen_spearman_v04}} at one year, {{fen_spearman_v12}} at five) but also drifted.

Conditioning on the continuous phenotype axis attenuated the stable between-person association between pain and motor severity by {{fen_atenua_total}} for the total motor score and {{fen_atenua_resto}} for the score excluding classifier items. The phenotype axis therefore accounts for part of the shared variation without accounting for all of it.

---

## Discussion

In a cohort of recently diagnosed patients followed annually for five years, pain and motor severity covaried as stable characteristics of the patient rather than as a sequence in which one preceded the other. Pain marked a persistently higher level of motor impairment, not a faster rate of progression. The association survived formal handling of time-varying confounding by dopaminergic dose but shrank by more than a third. The motor phenotype, though associated with pain, did not modify the relationship.

### What the between-person and within-person separation adds

The most consequential result is methodological in origin but substantive in implication. Fitting the conventional cross-lagged model to these data yields significant paths in both directions and would support a narrative of reciprocal causation. That narrative dissolves once stable between-person differences are separated: the motor-to-pain path is null, the pain-to-motor path is fragile, and the stable correlation is what remains and is robust.

This matters beyond this cohort, because the direction most often asserted in this literature is precisely the one that disappears here. Studies asserting that motor disease drives pain have generally not separated these two sources of variation, and the pattern we observe is what such an analysis would produce if patients simply differ stably in both quantities.

The practical implication is that pain in early Parkinson disease is better read as a marker of where a patient sits than as a signal of where they are heading. It identifies patients with more motor impairment at every point in follow-up, which is clinically useful, but it does not identify patients who will deteriorate faster.

### Why the phenotype hypothesis failed

We predicted that pain would concentrate in the akinetic-rigid presentation and that its association with motor severity would be stronger there. The first half held; the second did not.

Two features of the classification bear on this. First, the phenotype is not the stable trait the hypothesis requires. Agreement with the baseline class fell to under two thirds by year 5, consistent with independent reports that most baseline tremor dominant patients do not remain so. A construct that reclassifies a third of patients within a year cannot carry a claim about stable mechanism. Second, and relatedly, the classifier is partly a running index of severity rather than a description of type: drift is driven by accumulating gait and balance scores, which are also the outcome.

That second point is the strongest competing explanation for our central finding, and we cannot exclude it. If axial and non-dopaminergic burden increases with disease severity, and pain also increases with it, then the stable covariation we observe reflects a shared severity dimension rather than any specific link between nociception and motor control. Consistent with this, conditioning on the continuous phenotype axis removed a substantial share of the covariation but not all of it.

### The specificity of the finding is limited

Our negative control constrains the interpretation in an important way. Pain did not predict change in MoCA, which argues against pain being a general marker of faster decline. But the stable between-person correlation of pain was not confined to motor severity: it extended to cognition (r = {{refut_moca_rasgo_r}}, p = {{refut_moca_rasgo_p}}).

Level and change are different questions, and the two results are not contradictory. Still, the explanation that pain marks a general profile of greater burden rather than a specific relationship with motor function remains live, and we do not claim to have excluded it.

### Strengths

The cohort is large, recently diagnosed, initially untreated, and followed annually with a standardised motor examination in a defined medication state. Exposure and outcome do not share measurement method: pain is patient-reported and the motor examination is rated by a clinician, so shared-method correlation cannot explain the association. Exclusion for deep brain stimulation was applied without conditioning on the future, which matters because the naive approach removes precisely the patients who progress most. Attrition, time-varying confounding and multiplicity were handled explicitly rather than acknowledged in passing, and each analysis that produced a result we favoured was subjected to a documented attempt at refutation before being accepted.

### Limitations

The exposure is a single ordinal item that averages pain of different mechanisms. A validated Parkinson-specific pain instrument would allow the question to be asked of each subtype, and might well give different answers for musculoskeletal, dystonic and central pain. This is the single most important limitation.

Attrition is severe, and although censoring weights were close to one and did not move the estimates, weighting can only correct for measured predictors of dropout. Horizon-specific estimates beyond the first year rest on progressively smaller and more selected samples and should not be read individually.

The E-value of {{evalue_puntual}} indicates that an unmeasured confounder of modest strength would suffice to explain away the 12-month association. This is not a strong result on that axis, and we present it as such.

The causal estimand requires care. Pain is a state, not an intervention. "The effect of having pain" does not define a counterfactual without specifying how one would intervene, whether by analgesia, by treating dystonia or by adjusting dopaminergic control, and each of those would have a different effect. What the marginal structural model estimates is a weighted contrast under an explicit causal structure, not the effect of an assignable treatment.

Finally, the analysis was reframed after the results were known. The evidence and reasoning behind that change are documented, and readers can reconstruct and disagree with the decision, but it remains a change made after seeing the data.

### Conclusions

In early Parkinson disease, pain and motor severity coexist as stable characteristics of the patient. Neither precedes the other on the annual timescale this cohort can resolve, and pain marks the level of motor impairment rather than its rate of change. Analyses that do not separate stable between-person differences from within-person change will tend to find reciprocal causation where none is demonstrable.

---

## Data and code availability

Data are available from the Parkinson's Progression Markers Initiative under its data use agreement and are not redistributed here. All analysis code, the enrolment flow, the exported numerical results and the dated decision records are available in the accompanying public repository. Continuous integration verifies at every change that no participant-level data are committed.
