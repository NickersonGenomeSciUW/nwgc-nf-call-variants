process VALIDATE_VARIANTS {

    label "VALIDATE_VARIANTS_${params.sampleId}_${params.userId}"

    input:
        path gvcf

    output:
        path  "*.error.txt", emit: errorText

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        def chromosomesToCheck = ""
        if ("$params.organism" == 'Homo sapiens') {
            def chromsomsesToCheckPrefix = " -L"
            chromosomesToCheck += chromsomsesToCheckPrefix + " "

            def chromosomes = "$params.isGRC38" ? "$params.grc38Chromosomes" : "$params.hg19Chromosomes"
            for (chromosome in chromosomes) {
                if (chromosome == " ") {
                    chromosomesToCheck += chromsomsesToCheckPrefix
                }
                chromosomesToCheck += chromosome
            }
        }

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
            -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar \
            -T ValidateVariants \
            -R $params.referenceGenome \
            -V $gvcf \
            --dbsnp $params.dbSnp \
            $chromosomesToCheck \
            --validateGVCF \
            --warnOnErrors

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}
