package org.apache.accumulo.core.util.shell.commands;

import java.io.IOException;

import org.apache.accumulo.core.client.AccumuloException;
import org.apache.accumulo.core.client.AccumuloSecurityException;
import org.apache.accumulo.core.client.BatchWriter;
import org.apache.accumulo.core.client.IteratorSetting;
import org.apache.accumulo.core.client.Scanner;
import org.apache.accumulo.core.client.TableNotFoundException;
import org.apache.accumulo.core.iterators.SortedKeyIterator;
import org.apache.accumulo.core.security.Authorizations;
import org.apache.accumulo.core.util.format.DeleterFormatter;
import org.apache.accumulo.core.util.shell.Shell;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;


public class DeleteManyCommand extends ScanCommand {
	private Option forceOpt, tableOpt;

	public int execute(String fullCommand, CommandLine cl, Shell shellState) throws AccumuloException, AccumuloSecurityException, TableNotFoundException, IOException, ParseException {
		
		String tableName;
		
		if(cl.hasOption(tableOpt.getOpt())){
			tableName = cl.getOptionValue(tableOpt.getOpt());
			if (!shellState.getConnector().tableOperations().exists(tableName))
				throw new TableNotFoundException(null, tableName, null);
		}
		
		else{
			shellState.checkTableState();
			tableName = shellState.getTableName();
		}
		// handle first argument, if present, the authorizations list to
		// scan with
		Authorizations auths = getAuths(cl, shellState);
		final Scanner scanner = shellState.getConnector().createScanner(tableName, auths);

		scanner.addScanIterator(new IteratorSetting(1, "NOVALUE", SortedKeyIterator.class));

		// handle remaining optional arguments
		scanner.setRange(getRange(cl));

		// handle columns
		fetchColumns(cl, scanner);

		// output / delete the records
		BatchWriter writer = shellState.getConnector().createBatchWriter(tableName, 1024 * 1024, 1000L, 4);
		shellState.printLines(new DeleterFormatter(writer, scanner, cl.hasOption(timestampOpt.getOpt()), shellState, cl.hasOption(forceOpt.getOpt())), false);

		return 0;
	}

	@Override
	public String description() {
		return "scans a table and deletes the resulting records";
	}

	@Override
	public Options getOptions() {
		forceOpt = new Option("f", "force", false, "forces deletion without prompting");
		Options opts = super.getOptions();
		
		tableOpt = new Option(Shell.tableOption, "table", true, "table to be created");
		tableOpt.setArgName("table");
		
		opts.addOption(forceOpt);
		opts.addOption(tableOpt);
		return opts;
	}

}