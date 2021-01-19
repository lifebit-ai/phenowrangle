#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/phenowrangle
========================================================================================
 lifebit-ai/phenowrangle Data Preparation Pipeline.
 #### Homepage / Documentation
 https://github.com/lifebit-ai/phenowrangle
----------------------------------------------------------------------------------------
*/

/*---------------------------------------
  Define and show help message if needed
-----------------------------------------*/

def helpMessage() {

    log.info"""
    
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --mode plink --pheno_data <S3/URL/PATH> --pheno_metadata <S3/URL/PATH>
    
    Essential parameters:
    --mode                           String containing type of desired output. Accepts 'plink'.
    --pheno_data                     Path to CSV file containing the phenotypic data to be used.
    --pheno_metadata                 Path to CSV containing metadata about the phenotypic variables. This helps the scripts to identify the schema and decide which transformation corresponds to each variable.
    
    Optional parameters:
    --id_column                      String defining the name of the ID column. Defaults to `Platekey_in_aggregate_VCF-0.0`    --gwas_cat_study_id              String containing GWAS catalogue study id
    --pheno_col                      Named of the phenotypic column of interest. Required for GWAS and pipelines requiring contrasts/regression.
    --query                          Path to file containing query resulting from filtering data in the CB.
    --design_mode                    String containing the type of design matrix wanted to be produced
    --case_group                     String containing the case group for the desired contrasts. 
    --continuous_var_transformation  Transforms continuous variables using 'log', 'log10', 'log2', 'zscores' or 'None'.
    --continuous_var_aggregation     Defines how to aggregate different measurements. Choose between 'max', 'min', 'median' or 'mean'.
    --trait_type                     Type of regression being executed: 'binary' or 'quantitative'
    --output_tag                     String with tag for files
    --outdir                         Path to output directory. Defaults to './results'
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}



/*---------------------------------------------------
  Define and show header with all params information 
-----------------------------------------------------*/

// Header log info

def summary = [:]

if (workflow.revision) summary['Pipeline Release'] = workflow.revision

summary['Max Resources']                  = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
summary['Output dir']                     = params.outdir
summary['Launch dir']                     = workflow.launchDir
summary['Working dir']                    = workflow.workDir
summary['Script dir']                     = workflow.projectDir
summary['User']                           = workflow.userName

summary['mode']                           = params.mode
summary['pheno_data']                     = params.pheno_data
summary['pheno_metadata']                 = params.pheno_metadata
summary['id_column']                      = params.id_column
summary['pheno_col']                      = params.pheno_col
summary['query']                          = params.query
summary['design_mode']                    = params.design_mode
summary['case_group']                     = params.case_group
summary['continuous_var_transformation']  = params.continuous_var_transformation
summary['continuous_var_aggregation']     = params.continuous_var_aggregation
summary['trait_type']                     = params.trait_type
summary['output_tag']                     = params.output_tag
summary['outdir']                         = params.outdir

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

/*--------------------------------------------------
  Channel preparation
---------------------------------------------------*/

ch_query =  params.query ? Channel.value(file(params.query)) : "None"
ch_pheno_data = params.pheno_data ? Channel.value(file(params.pheno_data)) : Channel.empty()
ch_pheno_metadata = params.pheno_metadata ? Channel.value(file(params.pheno_metadata)) : Channel.empty()

/*--------------------------------------------------
  Transform CB to plink phenofile data &
---------------------------------------------------*/

if (params.mode == 'plink'){

  //*  Ingest output from CB

    process transforms_cb_to_plink {
      tag "$name"
      publishDir "${params.outdir}/design_matrix", mode: 'copy'

      input:
      file(pheno_data) from ch_pheno_data
      file(pheno_metadata) from ch_pheno_metadata
      file(query_file) from ch_query

      output:
      file("${params.output_tag}.phe") into ch_transform_cb
      file("*.json") into ch_encoding_json
      file("*.csv") into ch_encoding_csv
      file("*id_code_count.csv") optional true into codes_pheno

      script:
      """
      cp /opt/bin/* .

      mkdir -p ${params.outdir}/design_matrix
      
      CB_to_plink_pheno.R --input_cb_data "$pheno_data" \
                            --input_meta_data "$pheno_metadata" \
                            --phenoCol "${params.pheno_col}" \
                            --query_file "${query_file}" \
                            --continuous_var_transformation "${params.continuous_var_transformation}" \
                            --continuous_var_aggregation "${params.continuous_var_aggregation}" \
                            --outdir "." \
                            --output_tag "${params.output_tag}"
      """
    }
}




/*--------------------------------------------------
  Design matrix generation for contrasts
---------------------------------------------------*/

//TODO: Check this later and finish it with the processes 
if (params.trait_type == 'binary' && params.case_group && params.design_mode != 'all_contrasts') {
  process add_design_matrix_case_group {
    tag "$name"
    publishDir "${params.outdir}/contrasts", mode: 'copy'

    input:
    file(pheFile) from ch_transform_cb
    file(json) from ch_encoding_json

    output:
    file("${params.output_tag}_design_matrix_control_*.phe") into (phenoCh_gwas_filtering, phenoCh)

    script:
    """
    cp /opt/bin/* .

    mkdir -p ${params.outdir}/contrasts

    create_design.R --input_file ${pheFile} \
                    --mode "${params.design_mode}" \
                    --case_group "${params.case_group}" \
                    --outdir . \
                    --output_tag ${params.output_tag} \
                    --phenoCol "${params.pheno_col}"
                      
    """
  }
}

if (params.trait_type == 'binary' && params.design_mode == 'all_contrasts') {
  process add_design_matrix_all{
    tag "$name"
    publishDir "${params.outdir}/contrasts", mode: 'copy'

    input:
    file(pheFile) from ch_transform_cb
    file(json) from ch_encoding_json

    output:
    file("${params.output_tag}_design_matrix_control_*.phe") into (phenoCh_gwas_filtering, phenoCh)

    script:
    """
    cp /opt/bin/* .

    mkdir -p ${params.outdir}/contrasts

    create_design.R --input_file ${pheFile} \
                    --mode "${params.design_mode}" \
                    --outdir . \
                    --output_tag ${params.output_tag} \
                    --phenoCol "${params.pheno_col}"
                      
    """
  }
}


/*
 * Completion e-mail notification
 */
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[lifebit-ai/phenowrangle] Successful: $workflow.runName"
    if (!workflow.success) {
        subject = "[lifebit-ai/phenowrangle] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // TODO nf-core: If not using MultiQC, strip out this code (including params.max_multiqc_email_size)
    // On success try attach the multiqc report
    def mqc_report = null
    try {
        if (workflow.success) {
            mqc_report = ch_multiqc_report.getVal()
            if (mqc_report.getClass() == ArrayList) {
                log.warn "[lifebit-ai/phenowrangle] Found multiple reports from process 'multiqc', will use only one"
                mqc_report = mqc_report[0]
            }
        }
    } catch (all) {
        log.warn "[lifebit-ai/phenowrangle] Could not attach MultiQC report to summary email"
    }

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.max_multiqc_email_size.toBytes() ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (email_address) {
        try {
            if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmail_html
            log.info "[lifebit-ai/phenowrangle] Sent summary e-mail to $email_address (sendmail)"
        } catch (all) {
            // Catch failures and try with plaintext
            def mail_cmd = [ 'mail', '-s', subject, '--content-type=text/html', email_address ]
            if ( mqc_report.size() <= params.max_multiqc_email_size.toBytes() ) {
              mail_cmd += [ '-A', mqc_report ]
            }
            mail_cmd.execute() << email_html
            log.info "[lifebit-ai/phenowrangle] Sent summary e-mail to $email_address (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File("${params.outdir}/pipeline_info/")
    if (!output_d.exists()) {
        output_d.mkdirs()
    }
    def output_hf = new File(output_d, "pipeline_report.html")
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File(output_d, "pipeline_report.txt")
    output_tf.withWriter { w -> w << email_txt }

    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
        log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
        log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
        log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
    }

    if (workflow.success) {
        log.info "-${c_purple}[lifebit-ai/phenowrangle]${c_green} Pipeline completed successfully${c_reset}-"
    } else {
        checkHostname()
        log.info "-${c_purple}[lifebit-ai/phenowrangle]${c_red} Pipeline completed with errors${c_reset}-"
    }

}


def nfcoreHeader() {
    // Log colors ANSI codes
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";

    return """    -${c_dim}--------------------------------------------------${c_reset}-
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  lifebit-ai/phenowrangle v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}
