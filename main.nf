#!/usr/bin/env nextflow
log.info "~~~ HowardJC's Pipeline ~~"
log.info "* reads:              ${params.reads}"
log.info "* outdir:             ${params.outdir}"
log.info "* Launch dir:         ${workflow.launchDir}"
log.info "* Work dir:           ${workflow.workDir}"
log.info "* Profile             ${workflow.profile ?: '-'}"
log.info "* Workflow container  ${workflow.container ?: '-'}"
log.info "* container engine    ${workflow.containerEngine?:'-'}"
log.info "* Nextflow run name   ${workflow.runName}"

Channel.fromFilePairs("$params.reads",flat:true).into{reads_ch}
println(reads_ch.view())
println("---------------------------------")


// println("------------")
// println(Channel.fromPath("$params.reads").view())


process cutadapt{
    input:
    tuple val(sample_id), file(sample_files), file(CLown) from reads_ch 
    path(queryFile) fromFilePairs(queryFile_ch)

    output:
    path("${queryFile}") into queryFile_ch1

    script:
    """
    cutadapt -a AGATCGGAAGAGC ${queryFile} | gzip 
    """
}


process fastqc{


    input:
    path(queryFile) from queryFile_ch1

    output: 
    path("fastqc_${queryFile}")  into fastqc_ch

    script:
    """
    mkdir fastqc_${queryFile}
    fastqc -o fastqc_${queryFile} -f fastq ${queryFile}
    """

}

process multimc{
    publishDir "${params.outdir}", mode: 'copy'
    input:
    path(Mea) from fastqc_ch.collect()

    output:
    path('multiqc_report.html')

    script:
    """
    multiqc ${Mea}
    """
    

}



