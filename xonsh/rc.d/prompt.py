import os
import platform

from xonsh.built_ins import XSH


def _tmux_osc7():
    """Emit OSC 7 for tmux directory tracking (invisible in prompt)."""
    if os.environ.get("TMUX"):
        cwd = os.getcwd()
        try:
            with open("/dev/tty", "w") as tty:
                tty.write(f"\033]7;file://{platform.node()}{cwd}\033\\")
                tty.flush()
        except OSError:
            pass
    return ""


def _compute_duration():
    if len(XSH.history.tss) > 0:
        start, end = XSH.history.tss[-1]
        elapsed = end - start
        if elapsed > 1:
            return "{{YELLOW}}{:.2f}s{{RESET}}".format(elapsed)
    return None


def _retcode():
    if XSH.history.rtns:
        if XSH.history.rtns[-1] != 0:
            return f"{{RED}}rv:{XSH.history.rtns[-1]}{{RED}}"
    return None


def expand_prompt_fields(prompt_fields):
    prompt_fields["_elapsed"] = _compute_duration
    prompt_fields["_retcode"] = _retcode
    prompt_fields["_tmux_osc7"] = _tmux_osc7
    return prompt_fields


def make_prompt() -> str:
    return "".join(
        (
            "<{#ffaf00}{localtime}{RESET}{_elapsed: {}}> ",
            "{env_name}{BOLD_BLUE}{short_cwd} ",
            "{#5dd8c8}{curr_branch:{} }{RESET}",
            "{_retcode:{} }{BOLD_PURPLE}${prompt_end}{RESET} ",
            "{_tmux_osc7}",  # OSC 7 at END so it fires last
        )
    )


XSH.env["PROMPT_FIELDS"] = expand_prompt_fields(XSH.env["PROMPT_FIELDS"])
XSH.env["PROMPT"] = make_prompt()
