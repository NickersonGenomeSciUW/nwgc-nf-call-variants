include { HAPLOTYPE_CALLER } from '../modules/haplotype_caller.nf'
include { ANNOTATE_VARIANTS } from '../modules/annotate_variants.nf'
include { FILTER_VARIANTS } from '../modules/filter_variants.nf'
include { COMBINE_GVCFS as COMBINE_GVCFS } from '../modules/combine_gvcfs.nf'
include { COMBINE_GVCFS as COMBINE_FILTERED_GVCFS } from '../modules/combine_gvcfs.nf'

workflow CALL_VARIANTS {

    main:
        ch_versions = Channel.empty()

        // Chromsomse to Call
        chromosomesToCall = Channel.fromList(params.hg19Chromosomes)
        if (params.isGRC38) {
            chromosomesToCall = Channel.fromList(params.grc38Chromosomes)
        }

        if (params.organism != 'Homo sapiens') {
            chromosomesToCall = Channel.fromList(['All'])
        }

        bamChannel = Channel.of(params.bam)
        chromosomesToCallTuple = chromosomesToCall.combine(bamChannel) 

        HAPLOTYPE_CALLER(chromosomesToCallTuple)

        ANNOTATE_VARIANTS(HAPLOTYPE_CALLER.out.gvcf_tuple)
        COMBINE_GVCFS('Main', ANNOTATE_VARIANTS.out.gvcf_tuple.collect())

        if (params.organism == 'Homo sapiens') {
            FILTER_VARIANTS(ANNOTATE_VARIANTS.out.gvcf_tuple)
            COMBINE_FILTERED_GVCFS('Filtered', FILTER_VARIANTS.out.gvcf_tuple.collect())
            ch_versions = ch_versions.mix(FILTER_VARIANTS.out.versions)
        }

        // Versions
        ch_versions = ch_versions.mix(HAPLOTYPE_CALLER.out.versions)
        ch_versions = ch_versions.mix(ANNOTATE_VARIANTS.out.versions)
        ch_versions = ch_versions.mix(COMBINE_GVCFS.out.versions)
        ch_versions.unique().collectFile(name: 'call_variants_software_versions.yaml', storeDir: "${params.sampleDirectory}")

    emit:
        gvcf = COMBINE_GVCFS.out.gvcf
}