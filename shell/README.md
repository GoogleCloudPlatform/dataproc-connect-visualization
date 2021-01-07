<br />
<p align="center">
  <h2 align="center">Connecting your Visualization Software to Hadoop on Google Cloud</h2>
  <img src="../images/cloud_dataproc.png" alt="Dataproc Logo">

  <p align="center">
    Companion scripts to set up your infrastructure step-by-step
    <br />
    <a href="https://cloud.google.com/solutions/migration/hadoop/architecture-for-connecting-visualization-software-to-hadoop-on-google-cloud">Architecture</a>
    ·
    <a href="https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud">Hands-on</a>
    ·
    <a href="../terraform/README.md">Terraform configuration</a>
    ·
    <a href="../README.md">Repo home</a>
  </p>
</p>

## Usage

This repository is a companion for the [step-by-step hands-on tutorial][second-part] on how to set up the architecture.<br >
Follow the instructions in the tutorial, and use the snippets in each file to follow along:

| Section | Snippets |
| ------- | -------- |
| [Before you begin][before-you-begin] | [1.before-you-begin.sh](1.before-you-begin.sh) |
| [Creating the backend cluster][create-backend-cluster] | [2.create-backend-cluster.sh](2.create-backend-cluster.sh) |
| [Creating the proxy cluster][create-proxy-cluster] | [3.create-proxy-cluster.sh](3.create-proxy-cluster.sh) |
| [Setting up authorization][set-up-authorization] | [4.set-up-authorization.sh](4.set-up-authorization.sh) |
| [Connecting from a BI Tool][connect-from-bi-tool] | [5.connect-from-bi-tool.sh](5.connect-from-bi-tool.sh) |


<!-- LINKS: https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[second-part]: https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud

[before-you-begin]: https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud#before-you-begin
[create-backend-cluster]: https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud#creating_the_backend_cluster
[create-proxy-cluster]: https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud#creating_the_proxy_cluster
[set-up-authorization]: https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud#setting_up_authorization
[connect-from-bi-tool]: https://cloud.google.com/solutions/migration/hadoop/connecting-visualization-software-to-hadoop-on-google-cloud#connecting_from_a_bi_tool
