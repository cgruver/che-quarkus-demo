## Work In Progress.  Demo coming soon...

Demo for Quarkus Dev Mode in Eclipse Che

   ```bash
   cat << EOF | oc apply -f -
   apiVersion: v1
   kind: Namespace
   metadata:
     name: eclipse-che-images
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: system:image-puller
     namespace: eclipse-che-images
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: system:image-puller
   subjects:
   - apiGroup: rbac.authorization.k8s.io
     kind: Group
     name: system:serviceaccounts
   ---
   apiVersion: image.openshift.io/v1
   kind: ImageStream
   metadata:
     name: quarkus
     namespace: eclipse-che-images
   ---
   apiVersion: build.openshift.io/v1
   kind: BuildConfig
   metadata:
     name: quarkus
     namespace: eclipse-che-images
   spec:
     source:
       dockerfile: |
         FROM registry.access.redhat.com/ubi9/ubi-minimal
         ARG USER_HOME_DIR="/home/user"
         ARG WORK_DIR="/projects"
         ARG JAVA_PACKAGE=java-17-openjdk-devel
         ARG USER_HOME_DIR="/home/user"
         ARG WORK_DIR="/projects"
         ENV HOME=${USER_HOME_DIR}
         ENV BUILDAH_ISOLATION=chroot
         ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
         ENV MAVEN_HOME=/usr/share/maven
         ENV MAVEN_CONFIG="${HOME}/.m2"
         ENV GRAALVM_HOME=/usr/local/tools/graalvm
         ENV JAVA_HOME=/etc/alternatives/jre_17_openjdk
         COPY --from=quay.io/cgruver0/che/quarkus-tools:latest /tools/ /usr/local/tools
         COPY --from=image-registry.openshift-image-registry.svc:5000/openshift/cli:latest /usr/bin/oc /usr/bin/oc
         RUN microdnf --disableplugin=subscription-manager install -y openssl compat-openssl11 libbrotli git tar gzip zip unzip which shadow-utils bash zsh wget jq podman buildah skopeo glibc-devel zlib-devel gcc libffi-devel libstdc++-devel gcc-c++ glibc-langpack-en ca-certificates ${JAVA_PACKAGE}; \
           microdnf update -y ; \
           microdnf clean all ; \
           mkdir -p ${USER_HOME_DIR} ; \
           mkdir -p ${WORK_DIR} ; \
           mkdir -p /usr/local/bin ; \
           setcap cap_setuid+ep /usr/bin/newuidmap ; \
           setcap cap_setgid+ep /usr/bin/newgidmap ; \
           mkdir -p "${HOME}"/.config/containers ; \
           (echo '[storage]';echo 'driver = "vfs"') > "${HOME}"/.config/containers/storage.conf ; \
           touch /etc/subgid /etc/subuid ; \
           chmod -R g=u /etc/passwd /etc/group /etc/subuid /etc/subgid ; \
           echo user:20000:65536 > /etc/subuid  ; \
           echo user:20000:65536 > /etc/subgid ; \
           chgrp -R 0 /home ; \
           chmod -R g=u /home ${WORK_DIR}
         USER 10001
         ENV PATH=${PATH}:/usr/local/tools/bin
         WORKDIR ${WORK_DIR}
     strategy:
       type: Docker
     output:
       to:
         kind: ImageStreamTag
         name: quarkus:latest
   EOF
   ```

1. Build the image:

   ```bash
   oc start-build quarkus -n eclipse-che-images -F
   ```

## Log into OpenShift Dev Spaces

1. Get the URL for the dev-spaces route:

   ```bash
   echo https://$(oc get route devspaces -n openshift-devspaces -o jsonpath={.spec.host})
   ```

1. Paste that URL into your browser and click `Log in with OpenShift`

   <img src="./readme-images/dev-spaces-login-openshift-oauth.png" width="50%"/>

1. Log in with user: `developer`, password: `developer`:

   <img src="./readme-images/openshift-local-login.png" width="50%"/>

1. The first time, you will be asked to authorize access:

   Click `Allow selected permissions`:

   <img src="./readme-images/login-authorize-access.png" width="50%"/>

1. You should now be at the Dev Spaces dashboard:

   <img src="./readme-images/create-workspace.png" width="75%"/>

## Add a role to your user

At this point we need to take a quick detour back to the terminal with `cluster-admin` privileges.  One capability that we need to enable Quarkus Dev Services, is not yet in Dev Spaces.  We need the ability to create `port-forward` from a pod in our namespace back to a running shell in our workspace.

Let's add that ability now, by creating a new `ClusterRole`, and binding our user to it in the namespace that Dev Spaces has provisioned for us.

1. Open a terminal and login to the OpenShift cluster as a user with `cluster-admin` privileges:

   If you are using the CRC install from above, it looks like this:

   ```bash
   oc login -u kubeadmin -p crc-admin https://api.crc.testing:6443
   ```

1. Create the cluster role:

   ```bash
   cat << EOF | oc apply -f -
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: quarkus-dev-services
   rules:
   - apiGroups:
     - batch
     resources:
     - jobs
     - jobs/status
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - ""
     resources:
     - pods/portforward
     verbs:
     - get
     - list
     - watch
     - create
     - delete
     - deletecollection
     - patch
     - update
   EOF
   ```

1. Add that role to your user in the provisioned namespace:

   ```bash
   oc policy add-role-to-user quarkus-dev-services developer -n developer-devspaces
   ```

## Create A Workspace

![T](./readme-images/create-workspace.png)

![](./readme-images/workspace-landing.png)

![](./readme-images/open-workspace.png)

![](./readme-images/workspace-theme-changed.png)

## Demo Quarkus Dev Services

![](./readme-images/open-terminal.png)

```bash
cd /projects
```

```bash
quarkus create
```

```bash
Creating an app (default project type, see --help).
Looking for the newly published extensions in registry.quarkus.io
-----------

applying codestarts...
📚  java
🔨  maven
📦  quarkus
📝  config-properties
🔧  dockerfiles
🔧  maven-wrapper
🚀  resteasy-reactive-codestart

-----------
[SUCCESS] ✅  quarkus project has been successfully generated in:
--> /projects/che-quarkus-demo/code-with-quarkus
-----------
Navigate into this directory and get started: quarkus dev
bash-5.1$ 
```

```bash
cd code-with-quarkus
```

```bash
mvn package
```

```bash
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running org.acme.GreetingResourceTest
2023-02-03 18:41:00,691 INFO  [io.quarkus] (main) code-with-quarkus 1.0.0-SNAPSHOT on JVM (powered by Quarkus 2.16.1.Final) started in 11.094s. Listening on: http://localhost:8081
2023-02-03 18:41:01,201 INFO  [io.quarkus] (main) Profile test activated. 
2023-02-03 18:41:01,201 INFO  [io.quarkus] (main) Installed features: [cdi, resteasy-reactive, smallrye-context-propagation, vertx]
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 21.581 s - in org.acme.GreetingResourceTest
2023-02-03 18:41:08,096 INFO  [io.quarkus] (main) code-with-quarkus stopped in 0.304s
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ code-with-quarkus ---
[INFO] Building jar: /projects/code-with-quarkus/target/code-with-quarkus-1.0.0-SNAPSHOT.jar
[INFO] 
[INFO] --- quarkus-maven-plugin:2.16.1.Final:build (default) @ code-with-quarkus ---
[INFO] [io.quarkus.deployment.QuarkusAugmentor] Quarkus augmentation completed in 8193ms
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  55.588 s
[INFO] Finished at: 2023-02-03T18:41:17Z
[INFO] ------------------------------------------------------------------------
```

```bash
quarkus ext add oidc
```

![](./readme-images/add-folder-to-workspace.png)

![](./readme-images/add-folder-to-workspace-select.png)

![](./readme-images/add-folder-to-worspace-confirm.png)

![](./readme-images/add-folder-to-workspace-trust.png)

`pom.xml`

```xml
<dependency>
  <groupId>io.quarkus</groupId>
  <artifactId>quarkus-test-keycloak-server</artifactId>
  <scope>test</scope>
</dependency>
```

`src/test/java/org/acme/GreetingResourceTest.java`

```java
package org.acme;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import io.quarkus.test.keycloak.client.KeycloakTestClient;

@QuarkusTest
public class GreetingResourceTest {

    KeycloakTestClient keycloak = new KeycloakTestClient();

    @Test
    public void testHelloEndpoint() {
        given()
          .auth().oauth2(getAccessToken("alice"))
          .when().get("/hello")
          .then()
             .statusCode(200)
             .body(is("Hello from RESTEasy Reactive"));
    }
    protected String getAccessToken(String user) {
        return keycloak.getAccessToken(user);
    }
}
```

`src/main/java/org/acme/GreetingResource.java`

```java
package org.acme;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import io.quarkus.security.Authenticated;
import javax.annotation.security.RolesAllowed;

@Path("/hello")
@Authenticated
public class GreetingResource {

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @RolesAllowed({"user","admin"})
    public String hello() {
        return "Hello from RESTEasy Reactive";
    }
}
```

![](./readme-images/open-split-terminal.png)

```bash
kubedock server --port-forward
```

```bash

```

```bash
export TESTCONTAINERS_RYUK_DISABLED=true
export TESTCONTAINERS_CHECKS_DISABLE=true
export DOCKER_HOST=tcp://127.0.0.1:2475
```

```bash
mvn test
```

![](./readme-images/mvn-test.png)