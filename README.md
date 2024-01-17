# Document AI Scanner

## Overview
The Document AI Scanner is an Oracle APEX 23.2 application that leverages the Oracle Cloud - Document Understanding AI Service in a modern APEX user interface. The aim of this application is to process several PDF or image files in one job and provide the results of the analysis as a ZIP file for download or export to an accounting database.

## Key Features
- **Text Extraction**: Extracts text from the scanned documents.
- **Table Extraction**: Identifies and extracts tables from the scanned documents.
- **Document Classification**: Classifies the type of document scanned.
- **Key-Value Extraction**: Extracts key-value pairs from the scanned documents.
- **Processor Job Details and Document Analysis Pages**: Provides detailed analysis results which can be displayed and improved.
- **Export to Accounting Database**: Allows for the export of the analysis data for further processing and decision-making.
- **Language Support**: Uses the discovered language to support proper date and number conversions using appropriate NLS-Settings.
- **Long Running Jobs**: Can wait for long running jobs without producing timeout error.
- **Downloadable Analysis**: The full analysis can be downloaded as a zip file.

## How it Works
The application accepts a set of files and then passed them to the Document Understanding AI Service for processing.
At the completion of the process, the application retrives the analysis results and stores them in sql tables.

The application uses a algorithm that improves the key-value results provided by the Document Understanding AI. This algorithm uses alias names, data type validation, and relative positions to form valid key-value pairs from text fragments with x,y-coordinates. It is extracting field values based on their position relative to the alias names in the text fragments.

## Getting Started
Install the file Document AI Scanner App.sql as an APEX application in your Oracle Autonomous database. Also install the supporting objects in the installation process.
Follow the detailed installation instructions in the "Document AI Scanner App - Application Guide.pdf" to enable the connections to the REST-API and the object store. 

## Contributing
Contributions are welcome! Please read our contributing guidelines before getting started.

## License
MIT
