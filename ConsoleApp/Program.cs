using System;
using CommandLine;
using System.Threading.Tasks;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client; 

namespace partition_stats
{
    class Program
    {
        private DocumentClient Client { get; set; }
        private CommandLineOptions Options { get; set; }
        private Uri DocumentCollectionUri { get; set; }

        static void Main(string[] args)
        {
            try
            {
                CommandLine.Parser.Default.ParseArguments<CommandLineOptions>(args)
                    .WithParsed<CommandLineOptions>(opts => {
                        Program p = new Program { Options = opts };
                        p.Analyze(opts).Wait();
                    });
            }
            finally
            {
            }
        }

        private async Task Analyze(CommandLineOptions options)
        {
            using (this.Client = new DocumentClient(
                new Uri(options.DocumentDBEndpoint), 
                options.MasterKey, 
                new ConnectionPolicy { ConnectionMode = ConnectionMode.Gateway, ConnectionProtocol = Protocol.Tcp }))
            {
                DocumentCollectionUri = UriFactory.CreateDocumentCollectionUri(options.Database, options.Collection);

                DocumentCollection collection = await Client.ReadDocumentCollectionAsync(
                    DocumentCollectionUri,
                    new RequestOptions { PopulatePartitionKeyRangeStatistics = true } );

                Console.WriteLine(collection.PartitionKeyRangeStatistics.ToString());

                foreach(var partitionKeyRangeStatistics in collection.PartitionKeyRangeStatistics)
                {
                    Console.WriteLine("Partition Range Id {0}", partitionKeyRangeStatistics.PartitionKeyRangeId);
                    Console.WriteLine("Partition Document Count - {0}", partitionKeyRangeStatistics.DocumentCount);
                    Console.WriteLine("Partition Range Id Size (MB) - {0}", Math.Round(Convert.ToDouble(partitionKeyRangeStatistics.SizeInKB)/1024,2));
                    
                    foreach(var partitionKeyStatistics in partitionKeyRangeStatistics.PartitionKeyStatistics)
                    {
                        Console.WriteLine("Partition Key {0}", partitionKeyStatistics.PartitionKey);
                        Console.WriteLine("Partition Key Size (MB) - {0}", Math.Round(Convert.ToDouble(partitionKeyStatistics.SizeInKB)/1024,2));
                    }
                }

            }
        }
    }

    class CommandLineOptions
    {
        [Option('a', "account", HelpText = "DocumentDB account endpoint, e.g. https://docdb.documents.azure.com", Required= true)]
        public string DocumentDBEndpoint { get; set; }

        [Option('e', "masterKey", HelpText = "DocumentDB master key", Required = true)]
        public string MasterKey { get; set; }

        [Option('d', "database", HelpText = "DocumentDB database ID", Required = true)]
        public string Database { get; set; }

        [Option('c', "collection", HelpText = "DocumentDB collection ID", Required = true)]
        public string Collection { get; set; }

    }
}
