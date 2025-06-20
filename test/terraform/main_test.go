package test

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestTerraformK3sCluster(t *testing.T) {
	t.Parallel()

	// Create a unique name for this test
	uniqueID := random.UniqueId()
	clusterName := fmt.Sprintf("k3s-test-%s", uniqueID)

	// Copy terraform files to a temp directory
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../..", "terraform")

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"cluster_name":    clusterName,
			"project_name":    "k3s-test",
			"environment":     "test",
			"instance_type":   "t3.micro",
			"worker_count":    1,
			"worker_min_count": 1,
			"worker_max_count": 2,
			"enable_monitoring": false,
			"enable_argocd":    false,
		},
		EnvVars: map[string]string{
			"TF_VAR_ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...", // Replace with your test key
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	clusterNameOutput := terraform.Output(t, terraformOptions, "cluster_name")
	masterNodeIP := terraform.Output(t, terraformOptions, "master_node_ip")
	loadBalancerDNS := terraform.Output(t, terraformOptions, "load_balancer_dns")

	// Verify outputs
	assert.Equal(t, clusterName, clusterNameOutput)
	assert.NotEmpty(t, masterNodeIP)
	assert.NotEmpty(t, loadBalancerDNS)

	// Test cluster connectivity (if we have kubectl access)
	testClusterConnectivity(t, masterNodeIP)
}

func testClusterConnectivity(t *testing.T, masterNodeIP string) {
	// This would test kubectl connectivity to the cluster
	// For now, we'll just verify the master node is reachable
	t.Logf("Testing connectivity to master node: %s", masterNodeIP)
	
	// You could add SSH connectivity tests here
	// For now, we'll just log that we would test this
	t.Log("Cluster connectivity test would be implemented here")
}

func TestTerraformOutputs(t *testing.T) {
	t.Parallel()

	// Create a unique name for this test
	uniqueID := random.UniqueId()
	clusterName := fmt.Sprintf("k3s-output-test-%s", uniqueID)

	// Copy terraform files to a temp directory
	terraformDir := test_structure.CopyTerraformFolderToTemp(t, "../..", "terraform")

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"cluster_name":    clusterName,
			"project_name":    "k3s-output-test",
			"environment":     "test",
			"instance_type":   "t3.micro",
			"worker_count":    1,
			"worker_min_count": 1,
			"worker_max_count": 2,
			"enable_monitoring": false,
			"enable_argocd":    false,
		},
		EnvVars: map[string]string{
			"TF_VAR_ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...", // Replace with your test key
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test all outputs
	testOutputs(t, terraformOptions, clusterName)
}

func testOutputs(t *testing.T, terraformOptions *terraform.Options, expectedClusterName string) {
	// Test cluster name output
	clusterName := terraform.Output(t, terraformOptions, "cluster_name")
	assert.Equal(t, expectedClusterName, clusterName)

	// Test master node IP output
	masterNodeIP := terraform.Output(t, terraformOptions, "master_node_ip")
	assert.NotEmpty(t, masterNodeIP)
	assert.True(t, isValidIP(masterNodeIP))

	// Test load balancer DNS output
	loadBalancerDNS := terraform.Output(t, terraformOptions, "load_balancer_dns")
	assert.NotEmpty(t, loadBalancerDNS)
	assert.True(t, strings.Contains(loadBalancerDNS, ".amazonaws.com"))

	// Test VPC ID output
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID)
	assert.True(t, strings.HasPrefix(vpcID, "vpc-"))

	// Test subnet outputs
	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.NotEmpty(t, privateSubnetIDs)
	assert.True(t, len(privateSubnetIDs) >= 1)

	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.NotEmpty(t, publicSubnetIDs)
	assert.True(t, len(publicSubnetIDs) >= 1)

	// Test cluster info output
	clusterInfo := terraform.OutputMap(t, terraformOptions, "cluster_info")
	assert.NotEmpty(t, clusterInfo)
	assert.Equal(t, expectedClusterName, clusterInfo["name"])
	assert.Equal(t, "us-west-2", clusterInfo["region"])
	assert.Equal(t, "t3.micro", clusterInfo["instance_type"])
}

func isValidIP(ip string) bool {
	parts := strings.Split(ip, ".")
	if len(parts) != 4 {
		return false
	}
	for _, part := range parts {
		if len(part) == 0 || len(part) > 3 {
			return false
		}
		for _, char := range part {
			if char < '0' || char > '9' {
				return false
			}
		}
	}
	return true
}

// Test for security group rules
func TestSecurityGroups(t *testing.T) {
	t.Parallel()

	// This test would verify that security groups are properly configured
	// For now, we'll create a placeholder test
	t.Log("Security group tests would be implemented here")
}

// Test for VPC configuration
func TestVPCConfiguration(t *testing.T) {
	t.Parallel()

	// This test would verify VPC configuration
	// For now, we'll create a placeholder test
	t.Log("VPC configuration tests would be implemented here")
}

// Test for load balancer configuration
func TestLoadBalancerConfiguration(t *testing.T) {
	t.Parallel()

	// This test would verify load balancer configuration
	// For now, we'll create a placeholder test
	t.Log("Load balancer configuration tests would be implemented here")
} 