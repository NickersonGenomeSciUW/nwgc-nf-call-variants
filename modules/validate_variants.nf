process VALIDATE_VARIANTS {

    label "VALIDATE_VARIANTS_${params.sampleId}_${params.userId}"

    input:
        path gvcf
        path index

    output:
        path  "error.txt", emit: errorFile

    script:
        def taskMemoryString = "$task.memory"
        def javaMemory = taskMemoryString.substring(0, taskMemoryString.length() - 1).replaceAll("\\s","")

        def chromosomesToCheck = ""
        if ("$params.organism" == 'Homo sapiens') {
            def chromsomsesToCheckPrefix = " -L "
            def chromosomes = "$params.isGRC38" == 'true' ? Eval.me("$params.grc38Chromosomes") : Eval.me("$params.hg19Chromosomes")
            for (chromosome in chromosomes) {
                chromosomesToCheck += chromsomsesToCheckPrefix + chromosome
            }
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

        grep WARN .command.out | grep '\\*\\*\\*\\*\\*'  > error.txt

        cat <<-END_VERSIONS > versions.yaml
        '${task.process}':
            gatk: \$(java -jar \$MOD_GSGATK_DIR/GenomeAnalysisTK.jar --version)
        END_VERSIONS

        """

}
