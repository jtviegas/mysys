# mysys
configurations for my system (laptop)

## getting started

* create `~/.mysys/bin` folder:
    ```
    mkdir -p ~/.mysys/bin
    ```

* download `mysys.sh` script
  * ... from `~/.mysys/bin` folder
    ```
    cd ~/.mysys/bin
    wget https://raw.githubusercontent.com/jtviegas/mysys/main/.mysys/bin/mysys.sh
    ```
  * make it executable: `chmod +x mysys.sh`
  * update __mysys__ with latest version from the github repo: `./mysys.sh update`

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
* __source__ the `.mysys/env/include` file in your system's profile initialisation file ( `.zprofile`, `.bash_profile`, etc... )
    ```
    . ~/.mysys/env/include
    ```
* restart the system
* you should now invoke `mysys.sh` from everywhere in your terminal
  ```
  ~ % mysys.sh
   [DEBUG] Wed Nov 12 17:36:25 CET 2025 ... 1:  2:  3:  4:  5:  6:  7:  8:  9:
    usage:
    mysys.sh { command }

      commands:
        - update: updates 'mysys'
  ```

## usage

* export system wide variables and secrets from within your local __mysys__ files, they will be loaded every time the system starts:
  * `~/.mysys/env/.variables`
  * `~/.mysys/env/.secrets`

* access various utility scripts provided by __mysys__ in the terminal, as in:
  * `mysys_*`

