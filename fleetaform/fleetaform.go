package fleetaform

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"github.com/rs/zerolog/log"
	"gopkg.in/yaml.v3"
	"os/exec"
	"strings"
)

// Fleetaform sets up fleet test clusters via k3d. Networks, clusters, and all other named objects are prefixed
// with prefix, version is the fleet version to deploy, count is the number of downstream clusters
func Fleetaform(prefix string, version string, count uint) error {
	clusterName := prefix
	networkName := prefix + "-network"

	createSharedNetwork(networkName)
	createK3dCluster(clusterName, networkName)
	installFleetChart("fleet-crd", version, Values{}, clusterName)
	installFleetChart("fleet", version, Values{}, clusterName)
	values := generateAgentChartValues(clusterName)

	for i := uint(0); i < count; i++ {
		downstreamClusterName := fmt.Sprintf("%v-downstream-%v", prefix, i)
		createK3dCluster(downstreamClusterName, networkName)
		installFleetChart("fleet-agent", version, values, downstreamClusterName)
	}

	return nil
}

func createSharedNetwork(name string) {
	log.Info().Msgf("Creating shared network %v for clusters to communicate...", name)

	output := run("docker", "network", "list", "--format", "{{.Name}}", "--filter", "name="+name)
	if !strings.Contains(output, name) {
		run("docker", "network", "create", name)
	}
}

func createK3dCluster(name string, network string) {
	log.Info().Msgf("Creating cluster %v...", name)

	output := run("k3d", "cluster", "list", "--output=yaml")
	clusters := make([]K3dCluster, 0)
	err := yaml.Unmarshal([]byte(output), &clusters)
	if err != nil {
		log.Error().Msg("Error unmarshaling output from k3d")
		log.Fatal().Err(err).Send()
	}
	found := false
	for _, cluster := range clusters {
		if cluster.Cluster.Name == name {
			found = true
			break
		}
	}
	if !found {
		run("k3d", "cluster", "create", name, "--network", network, "--no-lb", "--wait")
	}
}

func installFleetChart(chart string, version string, values Values, clusterName string) {
	log.Info().Msg(fmt.Sprintf("Installing chart %v on cluster %v...", chart, clusterName))

	valueBytes, err := yaml.Marshal(values)
	if err != nil {
		log.Error().Msg("Error marshaling values for helm")
		log.Fatal().Err(err).Send()
	}
	context := "k3d-" + clusterName
	runWithStdin(string(valueBytes), "helm", "--kube-context="+context, "--namespace", "fleet-system",
		"upgrade", "--install", "--create-namespace", "--wait", "--values", "-",
		chart,
		fmt.Sprintf("https://github.com/rancher/fleet/releases/download/v%v/%v-%v.tgz", version, chart, version),
	)
}

func generateAgentChartValues(clusterName string) Values {
	log.Info().Msg("Generating token to register downstream clusters...")
	manifest := `kind: ClusterRegistrationToken
apiVersion: "fleet.cattle.io/v1alpha1"
metadata:
  name: fleet-token
  namespace: fleet-local
spec:
  # infinite
  ttl: 240h
`
	context := "k3d-" + clusterName
	runWithStdin(manifest, "kubectl", "--context="+context, "apply", "-f", "-")
	run("kubectl", "--context="+context, "--namespace=fleet-local", "wait", "--for=jsonpath=.status.secretName=fleet-token", "clusterregistrationtoken/fleet-token")
	encodedToken := run("kubectl", "--context="+context, "--namespace=fleet-local", "get", "secret", "fleet-token", "--output=jsonpath={.data.values}")
	tokenBytes, err := base64.StdEncoding.DecodeString(encodedToken)
	if err != nil {
		log.Fatal().Msg("Error base64 decoding token")
	}
	var values Values
	err = yaml.Unmarshal(tokenBytes, &values)
	if err != nil {
		log.Error().Msg("Error unmarshaling output from kubectl")
		log.Fatal().Err(err).Send()
	}

	// fix up values.yaml with correct URL and CA
	encodedCAData := run("kubectl", "--context="+context, "config", "view", "--flatten", "--output=jsonpath={.clusters[?(@.name == '"+context+"')].cluster.certificate-authority-data}")
	caData, err := base64.StdEncoding.DecodeString(encodedCAData)
	if err != nil {
		log.Fatal().Msg("Error base64 decoding token")
	}
	values.ApiServerURL = "https://" + context + "-server-0:6443"
	values.ApiServerCA = string(caData)
	return values
}

// helpers

// run executes a command and returns its standard output in a string
// panics in case of errors
func run(command string, arg ...string) string {
	return runWithStdin("", command, arg...)
}

// runWithStdin executes a command and returns its standard output in a string
// panics in case of errors, sends a string to stdin
func runWithStdin(stdin string, command string, arg ...string) string {
	log.Debug().Str("command", strings.Join(append([]string{command}, arg...), " ")).Send()

	cmd := exec.Command(command, arg...)
	cmd.Stdin = strings.NewReader(stdin)
	var outBuf bytes.Buffer
	cmd.Stdout = &outBuf
	var errorBuf bytes.Buffer
	cmd.Stderr = &errorBuf

	err := cmd.Run()

	outString := outBuf.String()
	errorString := errorBuf.String()

	if outString != "" {
		log.Debug().Str("output", outBuf.String()).Send()
	}
	if errorString != "" {
		log.Debug().Str("error", errorBuf.String()).Send()
	}

	if err != nil {
		if outString != "" {
			log.Error().Msg(outBuf.String())
		}
		if errorString != "" {
			log.Error().Msg(errorBuf.String())
		}
		log.Fatal().Err(err).Str("command", command).Send()
	}

	return outBuf.String()
}

type K3dCluster struct {
	Cluster InnerCluster `yaml:"cluster"`
}

type InnerCluster struct {
	Name string `yaml:"name"`
}

type Values struct {
	ApiServerCA                 string `yaml:"apiServerCA"`
	ApiServerURL                string `yaml:"apiServerURL"`
	ClusterNamespace            string `yaml:"clusterNamespace"`
	SystemRegistrationNamespace string `yaml:"systemRegistrationNamespace"`
	Token                       string `yaml:"token"`
}
