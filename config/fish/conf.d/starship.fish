starship init fish | source
  
  function __ensure_starship_init --on-event fish_prompt
      if not set -q STARSHIP_SHELL
          starship init fish | source
      end
  end
