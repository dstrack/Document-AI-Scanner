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
- **Full Text Search**: Search with full text index in the searchable pdf files.
  
## How it Works
The application accepts a set of files and then passed them to the Document Understanding AI Service for processing.
At the completion of the process, the application retrives the analysis results and stores them in sql tables.

The application uses a algorithm that improves the key-value results provided by the Document Understanding AI. This algorithm uses alias names, data type validation, and relative positions to form valid key-value pairs from text fragments with x,y-coordinates. It is extracting field values based on their position relative to the alias names in the text fragments.

## Getting Started
Install the file Document AI Scanner App.sql as an APEX application in your Oracle Autonomous database. Also install the supporting objects in the installation process.
There is decent documentation https://github.com/dstrack/Document-AI-Scanner/blob/main/docs/Document%20AI%20Scanner%20App%20-%20Application%20Guide.pdf
Follow the detailed installation instructions in the "Document AI Scanner App - Application Guide.pdf" to enable the connections to the REST-API and the object store. 

The app uses the standard model of the AI service at the API endpoint: https://document.aiservice.eu-frankfurt-1.oci.oraclecloud.com/20221109/processorJobs

In the app there is a configuration page with all parameters. When installing the supporting objects, the SQL skips are installed from the repo. In the file Document_Scan_Ai_Field_Alias_DEU.sql you will find the German field aliases for the supported key-value pairs.

## Contributing
Contributions are welcome! Please read our contributing guidelines before getting started.

## License
MIT
