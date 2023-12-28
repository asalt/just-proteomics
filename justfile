# vim: set number relativenumber tabstop=4 shiftwidth=4 expandtab:
# Justfile for managing tasks in Echeverria project

thedate := `date +%Y%m%d`
LOG_FILE := "report_" + thedate + ".log"
FORCE := 'false'  # or 'true'

default:
    just -l

log-report:
    @echo "\nReport generated on" `date` >> {{LOG_FILE}}
    @echo 'generating report..'
    @echo '{{LOG_FILE}}'
    just generate-report >> {{LOG_FILE}}
    @echo "Report generation complete. See {{LOG_FILE}}"

generate-report:
    just find-files-extended MSPC000668
    just find-files-extended MSPC000735
    just find-files-extended MSPC000913
    just find-files-extended MSPC000955
    @echo "End of generate-report"

find-files-brief inputdir:
    @echo "# {{inputdir}}:"
    just find-raw-brief {{inputdir}}
    just find-mzml-brief {{inputdir}}

find-files-extended inputdir:
    just find-raw-extended {{inputdir}}
    just find-mzml-extended {{inputdir}}

find-raw-brief inputdir:
    @echo "# {{inputdir}}:"
    @echo "## Number of raw files:"
    find {{inputdir}} -type f -name "*.raw" | sort | wc -l

find-raw-extended inputdir:
    @echo "# {{inputdir}}:"
    @echo "## Number of raw files:"
    @find {{inputdir}} -type f -name "*.raw" | sort | wc -l
    @echo "## raw files:"
    @find {{inputdir}} -type f -name "*.raw" | sort
    @echo "## Number of compressed raw:"
    find {{inputdir}} -type f -name "*.raw.*z" | sort | wc -l
    @echo "## compressed raw files:"
    find {{inputdir}} -type f -name "*.raw.*z" | sort 


find-mzml-brief inputdir:
    @echo "# {{inputdir}}:"
    @echo "## Number of mzML files:"
    find {{inputdir}} -type f -name "*.mzML" | sort | wc -l

find-mzml-extended inputdir:
    @echo "# {{inputdir}}:"
    @echo "## Number of mzML files:"
    find {{inputdir}} -type f -name "*.mzML" | sort | wc -l
    @echo "## raw files:"
    find {{inputdir}} -type f -name "*.mzML" | sort
    @echo "## Number of compressed mzML:"
    find {{inputdir}} -type f -name "*.mzML.*z" | sort | wc -l
    @echo "## compressed mzML files:"
    find {{inputdir}} -type f -name "*.mzML.*z" | sort 


# Extract directory from input file
convert-to-mzml inputfile: # remember this must be bash compatable. we use variable expansion here
    #!/usr/bin/env bash
    DIRNAME=$(dirname {{inputfile}})
    BASENAME=$(basename {{inputfile}})
    echo $DIRNAME
    cd $DIRNAME
    docker run -it --rm -e WINEDEBUG=-all -v $(pwd):/data chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:latest wine msconvert\
     --filter "peakPicking true 1-" $BASENAME


log-to-json:
    mistletoe {{ LOG_FILE }} --renderer mistletoe.ast_renderer.AstRenderer > "{{ LOG_FILE }}.json"

# https://til.simonwillison.net/python/generate-nested-json-summary
summarize-json:
    python ./just-scripts/summarize_json.py {{ LOG_FILE }}.json



find-and-convert-mzml inputdir:
    #!/usr/bin/env bash
    for file in $(find {{inputdir}} -type f -name '*.raw'); do
        mzml_file="${file%.raw}.mzML"
        if [[ -f "$mzml_file" && "{{FORCE}}" == "false" ]]; then
            echo "Skipping $file as $mzml_file already exists"
            continue
        fi
        echo "Processing $file"
        #just convert-to-mzml $file
    done


group-files inputdir:
    #!/usr/bin/env python
    import os
    import re
    rec_run_pat = re.compile("^\d+_\d+")
    for directory, subdirectories, files in os.walk("{{ inputdir }}"):
        print(directory, subdirectories)
        if len(files) == 0:
            continue
        for file in files:
            rec_run_value = rec_run_pat.match(file)
            if rec_run_value is None:
                continue # no match
            basename = rec_run_value.group() # will be \d+_\d+
            parent_directories = directory.split(os.sep)
            if any( basename == x for x in parent_directories): # we are in the right place
                continue
            # move to new place
            newdir = os.path.join(directory, basename)
            os.makedirs(newdir, exist_ok=True)
            # move file to new dir
            os.rename(os.path.join(directory, file), os.path.join(newdir, file))  # Move file

    
    

#relocate-recrun:

