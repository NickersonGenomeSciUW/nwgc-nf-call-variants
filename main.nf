include { CALL_VARIANTS } from './workflows/call_variants.nf'
include { VALIDATE_VARIANTS } from './modules/validate_variants.nf'

workflow {
    NwgcCore.init(params)

    CALL_VARIANTS()
    VALIDATE_VARIANTS(CALL_VARIANTS.out.gvcf, CALL_VARIANTS.out.gvcf_index)

    if (VALIDATE_VARIANTS.out.ERROR_TEXT != "") {
        error VALIDATE_VARIANTS.out.ERROR_TEXT
    }

}

workflow.onError {
    NwgcCore.error(workflow, "$params.sampleId")
}

workflow.onComplete {
    NwgcCore.processComplete(workflow, "$params.sampleId")
}
