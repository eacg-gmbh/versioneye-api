# Organisation API

## Inventory

The inventory endpoint returns all components which are used as dependencies inside of the given organisation. The simplest request would look like this: 

```
https://www.versioneye.com/api/v2/organisations/ORGA_NAME/inventory?api_key=API_KEY
```

For example:

```
https://www.versioneye.com/api/v2/organisations/versioneye/inventory?language=Java&api_key=0123456789
```

That will return a JSON object with this structure: 

```
{
  "LANGUAGE:PROD_KEY:NEWEST_VERSION": {
    "PROD_KEY::VERSION::LICENSE": [
      "LANGUAGE:PROJECT_NAME:PROJECT_ID:PROJECT_VERSION"
    ]
  }
}
```

The first row identifies the component, for example `Ruby:rails:5.0.0`. The 2nd shows in which concrete version that component is used and which license it has in that concrete version. For example `rails:4.0.0:MIT`. The value of that key is an Array with the user projects which are using that component (`rails`) in that concrete version (`4.0.0`). Here a complete example: 

```
{
  "Ruby:rails:5.0.0": {
    "rails::4.0.0::MIT": [
      "Ruby:My_first_ruby_project:1234567890:"
    ]
  }
}
```

And here is an example for Java: 

```
{
  "Java:org.apache.maven/maven-plugin-api:3.3.9": {
    "org.apache.maven/maven-plugin-api::3.3.9::Apache-2.0": [
      "Java:versioneye/versioneye_maven_plugin:544d0ff9512592562c000003:3.10.2",
      "Java:versioneye-maven-crawler:579e328f37cde6000d432c8e:1.2.0"
    ],
    "org.apache.maven/maven-plugin-api::3.0.5::Apache-2.0": [
      "Java:maven-indexer:56d6ba3dfa908e000e348ffc:1.1.3"
    ]
  },
  "Java:org.apache.maven/maven-core:3.3.9": {
    "org.apache.maven/maven-core::3.3.9::Apache-2.0": [
      "Java:versioneye/versioneye_maven_plugin:544d0ff9512592562c000003:3.10.2"
    ]
  }
}
```

The results can be filtered by: 

 - language 
 - team_name
 - project_version
 
Here is an example: 

```
https://www.versioneye.com/api/v2/organisations/versioneye/inventory?language=Java&project_version=3.10.2&api_key=0123456789
```

In the same fashion it's possible to filer by team name.
