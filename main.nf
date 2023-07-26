include { CALL_VARIANTS } from './workflows/call_variants.nf'
include { VALIDATE_VARIANTS } from './modules/validate_variants.nf'

workflow {
    NwgcCore.init(params)

    CALL_VARIANTS()
    VALIDATE_VARIANTS(CALL_VARIANTS.out.gvcf);

    if (VALIDATE_VARIANTS.out.errorText != "") {
        validationError = VALIDATE_VARIANTS.out.errorText
            error "Error:  ${validationError}."
    }
}

workflow.onError {
    NwgcCore.error(workflow, "$params.sampleId")
}

workflow.onComplete {
    NwgcCore.processComplete(workflow, "$params.sampleId")
}
