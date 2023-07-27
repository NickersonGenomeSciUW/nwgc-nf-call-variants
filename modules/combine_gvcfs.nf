
process COMBINE_GVCFS {

    label "COMBINE_GVCFS_${params.sampleId}_${params.userId}"

    publishDir "$params.sampleDirectory", mode:  'link', pattern: "combined.g.vcf.gz", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.${gvcf_type}.g.vcf.gz"}
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "combined.g.vcf.gz.tbi", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.${gvcf_type}.g.vcf.gz.tbi"}
    publishDir "$params.sampleDirectory", mode:  'link', pattern: "combined.g.vcf.gz.md5sum", saveAs: {s-> "${params.sampleId}.${params.sequencingTarget}.${gvcf_type}.g.vcf.gz.md5sum"}

    input:
        val gvcf_type
        path gvcfList

    output:
        path "combined.g.vcf.gz",  emit: gvcf
        path "combined.g.vcf.gz.tbi",  emit: tbi
        path "combined.g.vcf.gz.md5sum",  emit: sum
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        def gvcfsToCombine = " -V "
        def gvcfPrefix = " -V"
        def gvcfs = "$gvcfList"
        for (gvcf in gvcfs) {
            if (gvcf == " ") {
                gvcfsToCombine += gvcfPrefix
            }
            gvcfsToCombine += gvcf
        }

        """
        java "-Xmx$javaMemory" \
            -cp \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            org.broadinstitute.gatk.tools.CatVariants \
            -R $params.referenceGenome \
            --assumeSorted \
            -out combined.g.vcf \
            $gvcfsToCombine
    
        bgzip -f combined.g.vcf

        tabix -f combined.g.vcf.gz

        md5sum combined.g.vcf.gz | awk '{print \$1}' > combined.g.vcf.gz.md5sum

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
            tabix: \$(tabix 2>&1  | grep Version | awk '{print \$2}')
        END_VERSIONS

        """

}
