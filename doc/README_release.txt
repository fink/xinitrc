To release a new version of the xinitrc package:

* Commit all necessary changes.
  * If the package was modified directly in fink-dists, transfer the
    relevant changes as new commits available for the
    next release.
* Edit the ChangeLog and 'version' files for the new release version.
* Tag the tip of the repo, using the following format: v<FULLVERSION>
* Run the following command to generate the tarball and .info file:
  sh ./build.sh fink -r
* Copy the generated xinitrc.info file to fink-dists, and the new
  tarball to SF (into files/miscellaneous/mirror/ folder).
* Confirm that the package builds as expected.
* Push the new xinitrc.info to fink-dists.
