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

Channel.fromFilePairs("$params.reads",flat:true).set{queryFile_ch}


process cutadapt{

    input:
    tuple val(sample_id), file(sample_file1), file(sample_file2) from queryFile_ch 


    output:
    set path("${sample_file1}"), path("${sample_file2}") into queryFile_ch1

    script:
    // """
    // cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT ${sample_file1} ${sample_file2} | sponge | gzip 
    // """
    """
    cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -o Clowned.fastq.gz -p Card.fastq.gz -z  ${sample_file1} ${sample_file2} 
    cutadapt -q 20,20 -o Clowned.fastq.gz ${sample_file1} 
    cutadapt -q 20,20 -o Card.fastq.gz ${sample_file2}

    """

}


process fastqc{


    input:
    path(queryFile) from queryFile_ch1.flatten()

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
    path('Mea') from fastqc_ch.collect()

    output:
    path('multiqc_report.html')

    script:
    """
    multiqc ${Mea}
    """
    

}



