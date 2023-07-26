process VALIDATE_VARIANTS {

    label "VALIDATE_VARIANTS_${params.sampleId}_${params.userId}"

    input:
        path gvcf

    output:
        tuple val(chromosome), path(bam), path("*.filtered.g.vcf"),  emit: gvcf_tuple
        path  path("*.filtered.g.vcf"), emit: gvcf
        path "versions.yaml", emit: versions

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        def chromosomesToCheck = ""
        def chromsomsesToCheckPrefix = " -L "
        if ($params.organism == 'Homo sapiens') {
            def chromosomes = $params.isGRC38 ? $params.grc38Chromosomes : $params.hg19Chromosomes
            for (chromosome in chromosomes) {
                chromosomesToCheck = ${chromosomesToCheck}${chromsomsesToCheckPrefix}${chromosomes}
            }
        }

        """
        java "-Xmx$javaMemory" \
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T ValidateVariants \
            -R $params.referenceGenome \
            -V $gvcf \
            --dbsnp $DBSNP \
            $chromosomesToCheck \
            --validateGVCF \
            --warnOnErrors

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}