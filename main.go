package main

import (
	"fleetaform/fleetaform"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/urfave/cli/v2"
	"os"
)

func main() {
	app := cli.NewApp()
	app.Name = "fleetaform"
	app.Usage = "Sets up fleet test clusters via k3d"
	app.Version = "snapshot"
	app.Flags = []cli.Flag{
		&cli.StringFlag{
			Name:    "prefix",
			Aliases: []string{"p"},
			Usage:   "prefix of resources to deploy",
			Value:   "fleet",
		},
		&cli.UintFlag{
			Name:    "downstream-cluster-count",
			Aliases: []string{"n"},
			Usage:   "number of downstream clusters to deploy",
			Value:   3,
		},
		&cli.StringFlag{
			Name:    "fleet-version",
			Aliases: []string{"fv"},
			Usage:   "version of fleet to deploy",
			Value:   "0.3.9",
		},
		&cli.BoolFlag{
			Name:    "debug",
			Aliases: []string{"d"},
			Usage:   "extensive debugging output",
			Value:   false,
		},
	}

	app.Action = run
	if err := app.Run(os.Args); err != nil {
		log.Fatal().Err(err).Send()
	}
}

func run(ctx *cli.Context) error {
	// parse params
	prefix := ctx.String("prefix")
	downstreamClusterCount := ctx.Uint("downstream-cluster-count")
	fleetVersion := ctx.String("fleet-version")
	debug := ctx.Bool("debug")

	// set up logging
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	if debug {
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
	}

	// actually do the work
	return fleetaform.Fleetaform(prefix, fleetVersion, downstreamClusterCount)
}
