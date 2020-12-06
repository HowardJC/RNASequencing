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

Channel.fromPath("$params.reads").set{queryFile_ch}

process fastqc{


    input:
    path(queryFile) from queryFile_ch

    output: 
    path("fastqc_${queryFile}")  into fastqc_ch

    script:
    """
    mkdir fastqc_${queryFile}
    fastqc -o fastqc_${queryFile} -f fastq ${queryFile}
    """

}



