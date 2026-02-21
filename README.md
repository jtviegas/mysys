# mysys
configurations for my systems (laptop & Raspberry Pi)

## getting started

* run:
```
curl -LsSf https://raw.githubusercontent.com/jtviegas/mysys/main/bootstrap.sh | sh
```

you should now see this when running `./mysys.sh`:
```
 [WARN]  Wed Nov 12 17:31:16 CET 2025 *** we DON'T have a .variables variables file - creating it
 [WARN]  Wed Nov 12 17:31:16 CET 2025 *** we DON'T have a .secrets secrets file - creating it
 [DEBUG] Wed Nov 12 17:31:16 CET 2025 ... 1:  2:  3:  4:  5:  6:  7:  8:  9:
  usage:
  mysys.sh { command }

    commands:
      - update: updates 'mysys'
```
* __source__ the `.mysys/include` file in your system's profile initialisation file ( `.zprofile`, `.bash_profile`, `.bashrc`, etc... )
    ```
    . ~/.mysys/include
    ```
* restart the system
* you should now invoke `mysys.sh` from everywhere in your terminal
  ```
  ~ % mysys.sh
   [DEBUG] Wed Nov 12 17:36:25 CET 2025 ... 1:  2:  3:  4:  5:  6:  7:  8:  9:
    usage:
    mysys.sh { command }

      commands:
        - update:               updates 'mysys'
        - ssh_default_key       creates a default ssh key if none exists

  ```

## usage

* export system wide variables and secrets from within your local __mysys__ files, they will be loaded every time the system starts:
  * `~/.mysys/env/.variables`
  * `~/.mysys/env/.secrets`

* access various utility scripts provided by __mysys__ in the terminal, as in:
  * `mysys_*`

