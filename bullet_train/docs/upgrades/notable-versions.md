# Notable Versions

## v1.4.11 / v1.5.0

In v1.5.0 we made some fairly big changes to the format of system tests. In order to ease the
transition we shipped a helper in 1.4.11 that you can use to modify your copy of the tests before
you merge in version 1.5.0. Doing this should reduce the chances for merge conflicts.

To use the helper to modify your tests run this in a console (after updating to v1.4.11):

```
bin/update/system_tests/use_device_test
```

Then you should:

* Run the tests to make sure they still pass
* Commit the updated test files
* Update to v1.5.0

### Dealing with merge conflicts after merging v1.5.0

When you update to 1.5.0 you may have rather large merge conflicts in some system test files,
especially if you've modified those files to accomodate changes to user flows in your own app.

When you're resolving conflicts you'll mostly want to pick your own version of stuff (that is,
the code on the `HEAD` side of the conflict). If you want to avoid manually sorting a conflict
and just preserve your own version of a file you can do something like this:

```
git checkout HEAD -- test/system/the_test_file_in_question.rb
```

### About this change

We've introduced a new `device_test` helper that wraps up some of the implementation
details about running system tests on a variety of devices.

It simplifies the way that we write system tests like this:

```diff
-  @@test_devices.each do |device_name, display_details|
-    test "user can so something on a #{device_name}" do
-      resize_for(display_details)
-      # actual tests here
-    end
-  end
+  device_test "user can do something" do
+    # actual test code
+  end
```

The specific changes are:

* Remove the enclosing @@test_devices.each do block
* Remove one level of indentation from test inside those blocks
* Remove the resize_for(display_details) from tests in those blocks
* Use `device_test` helper to handle running the test on different devices


## v1.3.22

In version 1.3.22 we added an `Address` model. If your app already had an `Address` model you'll
probably want to reject some of the updates made to the starter repo in this version.

TODO: Can we offer more direction here?


## v1.3.0

Version 1.3.0 is when we started explicitly bumping the Bullet Train gems within the starter repo
every time that we release a new version of the `core` gems. Unfortunately, at that time we were
only making changes to Gemfile.lock which kind of hides the dependencies, and is often a source of
merge conflicts that can be hard to sort out.

[See the upgrade guide for getting your app to version 1.3.0](/docs/upgrades/yolo-130)
