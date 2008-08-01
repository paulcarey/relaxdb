= relaxdb

* No homepage yet

== DESCRIPTION:

RelaxDB provides a simple interface to CouchDB

== FEATURES/PROBLEMS:

* Removes impedance to persisting Ruby objects
* Immature
* A merb plugin is provided via merb_relaxdb (also on github)
* Uses ruby-cache to cache everything loaded and saved - this obviates n+1 query problems, but clearly doesn't work well if multiple CouchDB instances are replicating to one another. Proposed (but untested) solution is to set cache object expiration time to match CouchDB replication perdiod. Also note that ruby-cache needs to be modified so expiration occurs based not on last access, but on insertion time.
* Destroy results in non transactional nullification of child/peer references

== SYNOPSIS:

Look at spec/spec_models.rb to see how models are declared, and spec/relaxdb_spec.rb to see how they're used

== REQUIREMENTS:

* CouchDB 0.8.0

== INSTALL:

* Not yet available via gem - git clone and install via rake local_deploy

== LICENSE:

Copyright (c) 2008 Paul Carey

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.