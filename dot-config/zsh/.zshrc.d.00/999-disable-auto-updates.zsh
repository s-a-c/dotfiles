#!/usr/bin/env zsh
# 999-disable-auto-updates.zsh - Disable automatic updates when requested
# Phase: post-plugin augmentation (.zshrc.d.00)
# Purpose: Respect env toggle to prevent ZQS and OMZ from auto-updating (useful for testing/CI)
# Dependencies:
#   PRE: .zshenv exports ZF_DISABLE_AUTO_UPDATES
#   POST: none

case "${ZF_DISABLE_AUTO_UPDATES:-1}" in
	1|true|TRUE|yes|YES)
		# Disable ZQS auto-update checking
		unset QUICKSTART_KIT_REFRESH_IN_DAYS
		# Also ensure Oh-My-Zsh updates are disabled (should already be set by ZQS)
		export DISABLE_AUTO_UPDATE=true
		if typeset -f zf::debug >/dev/null 2>&1; then
			zf::debug "# [disable-auto-updates] Auto-updates disabled"
		fi
		;;
	*)
		if typeset -f zf::debug >/dev/null 2>&1; then
			zf::debug "# [disable-auto-updates] Auto-updates left enabled (ZF_DISABLE_AUTO_UPDATES=${ZF_DISABLE_AUTO_UPDATES})"
		fi
		return 0
		;;
esac

return 0
