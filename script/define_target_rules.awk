#!/usr/bin/gawk -f
# ------------------------------------------------------------------------------
# file: define_target_rules.awk
# type: GAWK program
# project: awkmake
#
# This program reads TACL source and creates part of a GNU Makefile
# ------------------------------------------------------------------------------

# ----
#BEGIN
# ----
BEGIN {
    IGNORECASE = 1 # gawk feature
    print ""
    print "# ---------------------------------------------"
    print "# Specific target rules"
    print "# ---------------------------------------------"
    print ""
}

# -------------
# Include library
# -------------
@include "script/library.awk" # @include is a gawk feature

# -------------
# Define functions
# -------------

# (****TODO remove section if none needed)

# -------------
# Process input
# -------------

# Ignore commented-out lines
/^[[:space:]]*==/ { next }

# Ignore empty lines
/^[[:space:]]*$/ { next }

# Look for a ?SECTION directive, get its name
/^[[:space:]]*\?SECTION[[:space:]]+([[:alpha:]][[:alnum:]_^]{0,30})/ {
    section = $2
    next
}

# Deal with section contents appropriately
// {
    switch (section) {

    case "define_targets":

        # Look for #DEF, signalling start of a new target definition
        if (match($0, /#DEF[[:space:]]+[^[:space:]]+[[:space:]]+STRUCT/) > 0) {
            $0 = substr($0, RSTART, RLENGTH)
            target_name = gensub(/:/, "", "g", $2)
            got_target_name = 1
            got_target_fname = 0
            got_target_log = 0
            got_target_secure = 0
            got_target_dependency_taclvar = 0
            got_target_recipe_taclvar = 0
        }
        
        # Look for a "FNAME name/log/secure VALUE..." line...
        if (match($0, /FNAME[[:space:]]+[[:alpha:]]+[[:space:]]+VALUE/) > 0) {
            file_type = $2

            switch (file_type) {
                case "name":
                    target_fname = gensub(/;/, "", "g", $4)
                    got_target_fname = 1
                    break
                case "log":
                    target_log = gensub(/;/, "", "g", $4)
                    got_target_log = 1
                    break
                case "secure":
                    target_secure = gensub(/;/, "", "g", $4)
                    got_target_secure = 1
                    break
                default:
                    # should not be able to get here
                    break
            }
        } # end if "FNAME name VALUE..." or "FNAME log VALUE..."

        # Look for a "STRUCT dependency" or "STRUCT recipe" line
        if (match($0, /^[[:space:]]+STRUCT[[:space:]]+/) > 0) {
            var_type = gensub(/;/, "", "g", $2)          
        }
        
        # Look for dependency or recipe variable name
        if (match($0, /^[[:space:]]+CHAR/) > 0) {
            match($0, /"[^"]+"/) # match 'doublequote-text-doublequote'
            switch (var_type) {
                case "dependency":
                    target_dependency_taclvar = substr($0, RSTART + 1, \
                        RLENGTH - 2)
                    got_target_dependency_taclvar = 1
                    break
                case "recipe":
                    target_recipe_taclvar = substr($0, RSTART + 1, RLENGTH - 2)
                    got_target_recipe_taclvar = 1
                    break
                default:
                    break
            }               
        }
        
        # Add the target data to targets_array
        if (\
            got_target_name && \
            got_target_fname && \
            got_target_log && \
            got_target_secure && \
            got_target_dependency_taclvar && \
            got_target_recipe_taclvar \
        ) {
            delete temp_array
            temp_array["target_name"] = target_name
            temp_array["target_fname"] = oss_fname_of(target_fname)
            temp_array["target_log"] = target_log
            temp_array["target_secure"] = oss_fname_of(target_secure)
            temp_array["target_dependency_taclvar"] = target_dependency_taclvar
            temp_array["target_recipe_taclvar"] = target_recipe_taclvar
            for (element in temp_array)
                targets_array[target_name][element] = temp_array[element] 
            got_target_name = 0
            got_target_fname = 0
            got_target_log = 0
            got_target_secure = 0
            got_target_dependency_taclvar = 0
            got_target_recipe_taclvar = 0
        }

        break # end case ?SECTION define_targets
    case /define_[[:alpha:]][[:alnum:]_]*[[:alnum:]]+_rule/:
 
         # Look for #DEF...dependency..." line
        if (match($0, /#DEF[[:space:]]+[^[:space:]]+_dependency[[:space:]]+/) \
              > 0 \
        ) {
            $0 = substr($0, RSTART, RLENGTH)
            target_dependency_label = gensub(/:/, "", "g", $2)
            got_dependency_label = 1
            got_dependency_info = 0
        }
        
        # ****TODO finish code! Till then, a stub:
        print "Stub. Got target dependency label: " target_dependency_label
#[#DEF :gs100obj_hello_dependency TEXT |BODY|
#  $(gs100obj_hello): $(gstalsrc_hello)
#  $(system_system_tal)
#]

        
        break # end case ?SECTION define_xxx_yyy_rule
    default:
        break
    }
}

# ---
# END
# ---
END { # ****TODO get rid of stub printer block, once development is complete
    for (i in targets_array) {
        for (j in targets_array[i])
            printf("%s ", targets_array[i][j])
        print ""
    }
    
}

# ------------------------------------------------------------------------------
# EOF
# ------------------------------------------------------------------------------
