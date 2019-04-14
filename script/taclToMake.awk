#!/usr/bin/gawk -f
# ------------------------------------------------------------------------------
# file: taclToMake.awk
# type: GAWK program
# project: gawkmake
#
# This program reads TACL source and creates a GNU Makefile
# ------------------------------------------------------------------------------

# ----
#BEGIN
# ----
BEGIN {
    IGNORECASE = 1 # gawk feature
    delete buildtacl_array
    delete clean_array
    delete ddldict_array
    delete deliverables_array
    delete dependencies_array
    delete secure_array
    delete sourcemap_array
    delete targets_array
    delete temp_array
}

# -------------
# Include library
# -------------
@include "script/library.awk" # @include is a gawk feature


# -------------
# Process the input
# -------------

# Ignore commented-out lines
/^[[:space:]]*==/ { next }

# Ignore empty lines
/^[[:space:]]*$/ { next }

# Look for a ?SECTION directive, get its name, assign it to section variable
/^[[:space:]]*\?SECTION[[:space:]]+([[:alpha:]][[:alnum:]_^]{0,30})/ {
    section = $2
    next
}

# Deal with section contents appropriately
// {
    switch (section) {

    case "define_buildtacl":
        build_buildtacl_array()
        break
        
    case "define_ddldict":
        build_ddldict_array()
        break

    case "define_dependencies":
        build_dependencies_array()
        break

    case "define_sourcemap":
        build_sourcemap_array()
        break
        
    case "define_targets":
        build_targets_arrays()
        break

    default:
        break
    }
}

# ---
# END
# ---
END {

    print "# ------------------------------------------------------------------"
    print "# file: build.mk"
    print "# type: GNU Make file"
    print "# **** This file was written by GAWK, reading the contents of"
    print "# **** build.tacl"
    print "# ------------------------------------------------------------------"
    print "\n"
    
    print "# ------------------------------------------------------------------"
    print "# variables"
    print "# ------------------------------------------------------------------"
    print ""
    
    print "# ----------------"
    print "# shell properties"
    print "# ----------------"
    print "SHELL = /bin/sh"
    print ".SHELLFLAGS = -ec"
    print ""

    print "# ---------------"
    print "# command aliases"
    print "# ---------------"
    print "RM := rm -Rf"
    print ""

    print "# -------------------------------"
    print "# build TACL file (target copies)"
    print "# -------------------------------"
    print "build_tacl_code180 := " oss_fname_of(buildtacl_array["bt180"])
    print "build_tacl_code101 := " oss_fname_of(buildtacl_array["bt101"])
    print ""
    clean_array["build_tacl_code180"] = "$(build_tacl_code180)"
    clean_array["build_tacl_code101"] = "$(build_tacl_code101)"
    
    print "# ---------------------------"
    print "# source and dependency files"
    print "# ---------------------------"
    for (row in dependencies_array) {
        dep_name = dependencies_array[row]["name"]
        printf("%s %s %s\n", dep_name,\
            ":=", oss_fname_of(dependencies_array[row]["file"])\
        )
    }
    print ""
    
    print "# -------------------------------------------------"
    print "# DDL dictionary - DICTODF tracks all modifications"
    print "# -------------------------------------------------"
    if (length(ddldict_array) > 0) {
        
        printf("%s%s%s", ddldict_array["name"], " := ",\
            oss_fname_of(ddldict_array["file"])\
        )
        print ""
        
    } else {
        print "# (none)"
    }
    print ""

    print "# --------------------------------------"
    print "# targets - intermediate and deliverable"
    print "# --------------------------------------"
    for (row in targets_array) {
        tgt_name = targets_array[row]["name"]
        printf("%s %s %s\n", tgt_name,\
            ":=", oss_fname_of(targets_array[row]["file"])\
        )
        clean_array[tgt_name] = "$(" tgt_name ")"
    }
    print ""

    print "# ------------"    
    print "# deliverables"
    print "# ------------"
    for (row in targets_array) {
        tgt_name = targets_array[row]["name"]
        deliverable = targets_array[row]["deliverable"]
        if (match(deliverable, /Y/) > 0) {
            deliverables_array[tgt_name] = tgt_name
        }
    }
    print "deliverables_list :="
    print "deliverables_list += \\"
    for (name in deliverables_array) {
        printf("%s%s%s%s", "  ", "$(", deliverables_array[name], ")")
        if (length(deliverables_array) > 1) {
            printf("%s", " \\")
        }
        print ""
        delete deliverables_array[name]
    } 
    print ""

    print "# ------------------------"
    print "# secure object repository"
    print "# ------------------------"
    for (name in secure_array) {
        print name "_securecopy := " oss_fname_of(secure_array[name])
    }
    print ""
    print "secure_object_list :="
    print "secure_object_list += \\"
    for (name in secure_array) {
        printf("%s%s%s%s", "  ", "$(", name, "_securecopy)")
        if (length(secure_array) > 1) {
            printf("%s", " \\")
        }
        print ""
    } 
    print ""

    print "# ----------------------------"
    print "# source subvolumes - C-format"
    print "# ----------------------------"
    for (row in sourcemap_array) {
        dir = sourcemap_array[row]["dir"]
        dir_sv180 = dir "_sv180" 
        printf("%s %s %s\n", dir_sv180,\
            ":=", oss_subvol_of(sourcemap_array[row]["sv180"])\
        )
       clean_array[dir_sv180] = "$(" dir_sv180 ")"
    }
    print ""
    
    print "# -------------------------------"
    print "# source subvolumes - EDIT-format"
    print "# -------------------------------"
    for (row in sourcemap_array) {
        dir = sourcemap_array[row]["dir"]
        dir_sv101 = dir "_sv101" 
        printf("%s %s %s\n", dir_sv101,\
            ":=", oss_subvol_of(sourcemap_array[row]["sv101"])\
        )
       clean_array[dir_sv101] = "$(" dir_sv101 ")"
    }
    print ""
    
    print "# -----------------------------------------"    
    print "# files/directories deleted by 'clean' rule"
    print "# -----------------------------------------"
    print "clean_list :="
    print "clean_list += \\"
    for (row in clean_array) {
        printf("%s%s", "  ", clean_array[row])
        if (length(clean_array) > 1) {
            printf("%s", " \\")
        }
        print ""
        delete clean_array[row]
    }
    print ""
    
    print "# ----------------------------------------------"
    print "# 'canned recipe' for deletion of DDL dictionary"
    print "# ----------------------------------------------"
    print "define cleanddl_recipe ="
    if (length(ddldict_array) > 0) {    
        name = ddldict_array["name"]
        print "touch $(" name ") # for gname, in case file doesn't exist"
        print "DICTODF=$$(gname -s $(" name "))"
        print "gtacl -c \"purge_ddldict $${DICTODF} ~; stop_cc\""
    } else {
        print ": # no DDL dictionary to delete"
    }
    print "endef"
    print ""
    
    print "# --------------------------------------"
    print "# 'canned recipe' for EDIT-format source"
    print "# --------------------------------------"
    print "define ctoedit_recipe ="
    print "FILE_180=$$(gname -s $<)"
    print "touch $@ # for gname, in case file doesn't exist"
    print "FILE_101=$$(gname -s $@)"
    print "$(RM) $@"
    print "gtacl -c \"CTOEDIT $${FILE_180}, $${FILE_101} ~; stop_cc\""
    print "endef"
    print ""
    
    print "# --------------"
    print "# tacl_cmd macro"
    print "# --------------"
    BUILD = buildtacl_array["bt101"]
    print "tacl_cmd = \\"
    print "  gtacl -c 'LOAD $" BUILD " ~; :define_all ~; $(1) ~; stop_cc'"
    print ""


    print "# ------------------------------------------------------------------"
    print "# rules"
    print "# ------------------------------------------------------------------"
    print ""

    print "# -------------------"
    print "# all == deliverables"
    print "# -------------------"
    print ".PHONY: all"
    print "all: $(deliverables_list)"
    print ""

    print "# -------------------------------"
    print "# update secure object repository"
    print "# -------------------------------"
    print ".PHONY: secure"
    print "secure: $(secure_object_list)"
    print ""

    print "# ----------------------------------"
    print "# delete targets if any error occurs"
    print "# ----------------------------------"
    print ".PHONY: .DELETE_ON_ERROR"
    print ".DELETE_ON_ERROR:"
    print ""

    print "# --------------------------------------------------------"
    print "# use same shell process for all statements in each recipe"
    print "# --------------------------------------------------------"
    print ".PHONY: .ONESHELL"
    print ".ONESHELL:"
    print ""

    print "# --------------------------------------------"
    print "# repository build.tacl -> C-format build TACL"
    print "# --------------------------------------------"
    print "$(build_tacl_code180): build.tacl"
    print "\t@cp --Wclobber $< $@"
    print ""

    print "# ---------------------------------------------"
    print "# C-format build TACL -> EDIT-format build TACL"
    print "# ---------------------------------------------"
    print "$(build_tacl_code101): $(build_tacl_code180)"
    print "\t@$(ctoedit_recipe)"
    print ""

    print "# ------------------------------------"
    print "# repository source -> C-format source"
    print "# ------------------------------------"
    for (row in sourcemap_array) {
        dir = sourcemap_array[row]["dir"]
        sv180 = oss_subvol_of(sourcemap_array[row]["sv180"])
        print sv180 "/%: src/" dir "/%"
        print "\t@cp --Wclobber $< $@"
        print ""
    }

    print "# -------------------------------------"
    print "# C-format source -> EDIT-format source"
    print "# -------------------------------------"
    for (row in sourcemap_array) {
        sv180 = oss_subvol_of(sourcemap_array[row]["sv180"])
        sv101 = oss_subvol_of(sourcemap_array[row]["sv101"])
        print sv101 "/%: " sv180 "/%"
        print "\t@$(ctoedit_recipe)"
        print ""
    }
    
    print "# --------------"
    print "# DDL dictionary"
    print "# --------------"
    if (length(ddldict_array) > 0) {
        name = ddldict_array["name"]
        delete ddldict_array["name"]
        file = ddldict_array["file"]
        delete ddldict_array["file"]
        logto = ddldict_array["logto"]
        delete ddldict_array["logto"]
        # Everything except dependencies has now been deleted from the array
        print ".PHONY: ddldict"
        print "ddldict: $(" name ")" 
        print "$(" name "): $(build_tacl_code101) \\"
        dependencies_per_line = 4
        i = 1
        for (label in ddldict_array) {
            printf("%s%s%s", "$(", ddldict_array[label], ") ")
            if (length(ddldict_array) == 1) { # last element
                print ""
            } else {
                if (i == (dependencies_per_line)) {
                    print "\\"
                    i = 1
                } else {
                    i++
                }
            }
            delete ddldict_array[label]
        }
        print "\t@echo Building DDL dictionary; DICTODF = \\$" file ","
        print "\t@echo logging to \\$" logto
        print "\t@$(call tacl_cmd, "name "_recipe)"
        print ""
    } else {
        print "# (none)"
        print ""
    }

    print "# -----------------------"
    print "# individual target rules"
    print "# -----------------------"
    for (row in targets_array) {
        name = targets_array[row]["name"]
        delete targets_array[row]["name"]
        file = targets_array[row]["file"]
        delete targets_array[row]["file"]
        logto = targets_array[row]["logto"]
        delete targets_array[row]["logto"]
        delete targets_array[row]["deliverable"]
        # Everything except dependencies has now been deleted from the row
        print ".PHONY: " name
        print name ": $(" name ")" 
        print "$(" name "): $(build_tacl_code101) \\"
        dependencies_per_line = 4
        i = 1
        for (label in targets_array[row]) {
            printf("%s%s%s", "$(", targets_array[row][label], ") ")
            if (length(targets_array[row]) == 1) { # last element
                print ""
            } else {
                if (i == (dependencies_per_line)) {
                    print "\\"
                    i = 1
                } else {
                    i++
                }
            }
            delete targets_array[row][label]
        }
        print "\t@echo Building \\$" file ", logging to \\$" logto
        print "\t@$(call tacl_cmd, "name "_recipe)"
        print ""
    }

    print "# -------------------------------------"
    print "# secure object repository update rules"
    print "# -------------------------------------"
    for (name in secure_array) {
        print "$(" name "_securecopy):  $(" name ")"
        print "\t@echo Updating secure object \\$" secure_array[name]
        print "\t@cp --Wclobber $< $@"
        print ""
    }

    print "# --------------------------------"
    print "# clean"
    print "# --------------------------------"
    print ".PHONY: clean"
    print "clean:"
    print "\t-@$(RM) $(clean_list)"
    print "\t-@$(cleanddl_recipe)"
    print ""


    print "# ------------------------------------------------------------------"
    print "# EOF"
    print "# ------------------------------------------------------------------"

}

# ------------------------------------------------------------------------------
# EOF
# ------------------------------------------------------------------------------
