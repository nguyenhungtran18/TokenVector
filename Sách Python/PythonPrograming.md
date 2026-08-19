Python
Programming
Hans-Petter Halvorsen
https://www.halvorsen.blog

Python Programming

Python Programming
Hans-Petter Halvorsen
2026

Python Programming
©Hans-Petter Halvorsen
June 12, 2026
ISBN:978-82-691106-4-7
1

Preface
Python is a popular programming language, and it is one of the most used pro-
| gramming | languages today. |     |     |     |     |
| -------- | ---------------- | --- | --- | --- | --- |
Pythonworksonallthemainplatformsandoperatingsystemsusedtoday,such
| Windows, | macOS, and | Linux. |     |     |     |
| -------- | ---------- | ------ | --- | --- | --- |
Python is a multi-purpose programming language, which can be use for simu-
| lation, creating | web pages, | communicate |     | with database | systems, etc. |
| ---------------- | ---------- | ----------- | --- | ------------- | ------------- |
| My Blog/Web      | Site [1]:  |             |     |               |               |
https://www.halvorsen.blog
Here you find lots of technical resources about Technology, Programming, Soft-
| ware Engineering, | Automation  |           | and Control, | Industrial | IT, etc. |
| ----------------- | ----------- | --------- | ------------ | ---------- | -------- |
| Here you          | find my Web | page with | Python       | resources: |          |
https://www.halvorsen.blog/documents/programming/python/
These resources are a supplement to this textbook. Here you can download the
| software, download | code       | examples,     | etc. |           |     |
| ------------------ | ---------- | ------------- | ---- | --------- | --- |
| This Textbook      | is written | in LATEXusing |      | Overleaf. |     |
LATEXis a document preparation system used for the communication and publi-
| cation of scientific | documents. |     |     |     |     |
| -------------------- | ---------- | --- | --- | --- | --- |
2

For more information about LATEX:
https://www.latex-project.org
Overleafisaweb-basesLATEXsystem,meaningyoucanwriteyourLATEXdocuments
in your web browser, you co-work and share documents with others.
For more information about Overleaf:
https://www.overleaf.com
Python Books
You find other Python textbooks within different domains on my Python Web
page:
https://www.halvorsen.blog/documents/programming/python/
Python Books:
• Python Programming - This is a textbook in Python Programming
withlotsofPracticalExamplesandExercises. Youwilllearnthenecessary
foundation for basic programming with focus on Python.
• Python for Science and Engineering - This is a textbook in Python
ProgrammingwithlotsofExamples,Exercises,andPracticalApplications
within Mathematics, Simulations, etc. The focus is on numerical calcu-
lations in mathematics and engineering. Necessary theory is presented in
addition to many practical examples.
• Python for Control Engineering - This is a textbook in Python Pro-
gramming with lots of Examples, Exercises, and Practical Applications
within Mathematics, Simulations, Control Systems, DAQ, Database Sys-
tems, etc. The focus is on the use of Python within measurements, data
collection (DAQ), control technology, both analysis of control systems
(stability analysis, frequency response, ...) and implementation of control
systems (PID, etc.). Required theory is presented in addition to many
practical examples and exercises in Python.
• PythonforSoftwareDevelopment-ThisisatextbookinPythonPro-
gramming with lots of Examples, Exercises, and Practical Applications
within Software Systems, Software Development, Software Engineering,
Database Systems, Web Application Desktop Applications, GUI Applica-
tions,etc. ThefocusisontheuseofPythonforcreatingmodernSoftware
Systems. Required theory is presented in addition to many practical ex-
amples and exercises in Python.
3

| Video | Resources |     |     |     |     |
| ----- | --------- | --- | --- | --- | --- |
In addition to the textbooks mentioned, lots of videos explaining and comple-
ments the different Python topics and examples within the textbook have been
| made. These | are | both available |     | on my website | and on YouTube. |
| ----------- | --- | -------------- | --- | ------------- | --------------- |
Blog:
https://www.halvorsen.blog
Python Resources:
https://www.halvorsen.blog/documents/programming/python/
| Python | Programming | Videos: |     |     |     |
| ------ | ----------- | ------- | --- | --- | --- |
https://www.youtube.com/playlist?list=PLdb-TcK6Aqj2l 1mtPqlOo−Yki5UPzp4
H
| Python | for Science | and Engineering |     | Videos: |     |
| ------ | ----------- | --------------- | --- | ------- | --- |
https://www.youtube.com/playlist?list=PLdb-TcK6Aqj2hlH55Bn5oxFIvyoVbXxQS
| Python | for Control | Engineering |     | Videos: |     |
| ------ | ----------- | ----------- | --- | ------- | --- |
https://www.youtube.com/playlist?list=PLdb-TcK6Aqj1Kg6pV3zlrpUnPIRwG2 O x
| Python | for Software | Development |     | Videos: |     |
| ------ | ------------ | ----------- | --- | ------- | --- |
https://www.youtube.com/playlist?list=PLdb-TcK6Aqj0E01L69fySfBSemVTCi L
l
| Raspberry | Pi and | Python: |     |     |     |
| --------- | ------ | ------- | --- | --- | --- |
https://www.youtube.com/playlist?list=PLdb-TcK6Aqj3Sf5omYT-MLmxckclHi2i7
| Internet | of Things | with Python: |     |     |     |
| -------- | --------- | ------------ | --- | --- | --- |
https://www.youtube.com/playlist?list=PLdb-TcK6Aqj2zP8b1JjzUcFGzTVG13BPh
| YouTube | Channel | @Industrial | IT  | and Automation |     |
| ------- | ------- | ----------- | --- | -------------- | --- |
https://www.youtube.com/IndustrialITandAutomation
Programming
The way we create software today has changed dramatically the last 30 years,
from the childhood of personal computers in the early 80s to today’s powerful
| devices | such as | Smartphones, | Tablets | and PCs. |     |
| ------- | ------- | ------------ | ------- | -------- | --- |
The Internet has also changed the way we use devices and software. We still
havetraditionaldesktopapplications, butWebSites, WebApplicationsandso-
called Apps for Smartphones, etc. are dominating the software market today.
We need to find and learn Programming Languages that are suitable for the
| New Age | of Programming. |     |     |     |     |
| ------- | --------------- | --- | --- | --- | --- |
We have today several thousand different Programming Languages today. I
guess you will need to learn more than one Programming Language to survive
4

| in today’s | software market.    |           |       |     |
| ---------- | ------------------- | --------- | ----- | --- |
| You find   | lots of Programming | Resources | here: |     |
https://www.halvorsen.blog/documents/programming/
| Software | Engineering |     |     |     |
| -------- | ----------- | --- | --- | --- |
Software Engineering is the discipline for creating software applications. A
systematic approach to the design, development, testing, and maintenance of
software.
| The main | parts or phases | in the Software | Engineering | process are: |
| -------- | --------------- | --------------- | ----------- | ------------ |
• Planning
| • Requirements | Analysis |     |     |     |
| -------------- | -------- | --- | --- | --- |
• Design
• Implementation
• Testing
| • Deployment | and              | Maintenance |                 |     |
| ------------ | ---------------- | ----------- | --------------- | --- |
| You find     | lots of Software | Engineering | Resources here: |     |
https://www.halvorsen.blog/documents/programming/software e ngineering/
5

6

Contents
I Getting Started with Python 11
1 Introduction 12
1.1 The New Age of Programming . . . . . . . . . . . . . . . . . . . 12
1.2 MATLAB . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 16
2 What is Python? 18
2.1 Introduction to Python . . . . . . . . . . . . . . . . . . . . . . . 18
2.1.1 Interpreted vs. Compiled . . . . . . . . . . . . . . . . . . 19
2.2 Python Packages . . . . . . . . . . . . . . . . . . . . . . . . . . . 20
2.2.1 Python Packages for Science and Numerical Computations 21
2.3 Anaconda . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 21
2.4 Python Editors . . . . . . . . . . . . . . . . . . . . . . . . . . . . 22
2.4.1 Python IDLE . . . . . . . . . . . . . . . . . . . . . . . . . 22
2.4.2 Visual Studio Code. . . . . . . . . . . . . . . . . . . . . . 23
2.4.3 Thonny . . . . . . . . . . . . . . . . . . . . . . . . . . . . 23
2.4.4 Spyder . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 23
2.4.5 Visual Studio . . . . . . . . . . . . . . . . . . . . . . . . . 23
2.4.6 PyCharm . . . . . . . . . . . . . . . . . . . . . . . . . . . 24
2.4.7 Wing Python IDE . . . . . . . . . . . . . . . . . . . . . . 24
2.4.8 Jupyter Notebook . . . . . . . . . . . . . . . . . . . . . . 24
2.5 Resources . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 25
2.6 Installing Python . . . . . . . . . . . . . . . . . . . . . . . . . . . 25
2.6.1 Python Windows 10 Store App . . . . . . . . . . . . . . . 25
2.6.2 Installing Anaconda . . . . . . . . . . . . . . . . . . . . . 26
2.6.3 Installing Visual Studio Code . . . . . . . . . . . . . . . . 26
3 Start using Python 27
3.1 Python IDE . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 27
3.2 My first Python program . . . . . . . . . . . . . . . . . . . . . . 27
3.3 Python Shell . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 28
3.4 Running Python from the Console . . . . . . . . . . . . . . . . . 28
3.4.1 Opening the Console on macOS. . . . . . . . . . . . . . . 29
3.4.2 Opening the Console on Windows . . . . . . . . . . . . . 30
3.4.3 Add Python to Path . . . . . . . . . . . . . . . . . . . . . 30
3.5 Scripting Mode . . . . . . . . . . . . . . . . . . . . . . . . . . . . 32
3.5.1 Run Python Scripts from the Python IDLE . . . . . . . . 32
3.5.2 Run Python Scripts from the Console (Terminal) macOS 33
7

3.5.3 Run Python Scripts from the Command Prompt in Win-
dows . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 34
3.5.4 Run Python Scripts from Spyder . . . . . . . . . . . . . . 34
4 Basic Python Programming 37
4.1 Basic Python Program . . . . . . . . . . . . . . . . . . . . . . . . 37
4.1.1 Get Help . . . . . . . . . . . . . . . . . . . . . . . . . . . 37
4.2 Variables . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 37
4.2.1 Numbers . . . . . . . . . . . . . . . . . . . . . . . . . . . 39
4.2.2 Strings. . . . . . . . . . . . . . . . . . . . . . . . . . . . . 40
4.2.3 String Input. . . . . . . . . . . . . . . . . . . . . . . . . . 41
4.3 Built-in Functions . . . . . . . . . . . . . . . . . . . . . . . . . . 41
4.4 Python Standard Library . . . . . . . . . . . . . . . . . . . . . . 42
4.5 Using Python Libraries, Packages and Modules . . . . . . . . . . 43
4.5.1 Python Packages . . . . . . . . . . . . . . . . . . . . . . . 45
4.6 Plotting in Python . . . . . . . . . . . . . . . . . . . . . . . . . . 45
4.6.1 Subplots . . . . . . . . . . . . . . . . . . . . . . . . . . . . 48
4.6.2 Exercises . . . . . . . . . . . . . . . . . . . . . . . . . . . 50
II Python Programming 51
5 Python Programming 52
5.1 If ... Else . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 52
5.2 Arrays . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 53
5.3 For Loops . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 55
5.3.1 Nested For Loops . . . . . . . . . . . . . . . . . . . . . . . 58
5.4 While Loops. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 59
5.5 Exercises . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 59
6 Creating Functions in Python 61
6.1 Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 61
6.2 Functions with multiple return values . . . . . . . . . . . . . . . 63
6.3 Exercises . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 64
7 Creating Classes in Python 67
7.1 Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 67
7.2 The init () Function . . . . . . . . . . . . . . . . . . . . . . . . 68
7.3 Exercises . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 71
8 Creating Python Modules 72
8.1 Python Modules . . . . . . . . . . . . . . . . . . . . . . . . . . . 72
8.2 Exercises . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 73
9 File Handling in Python 75
9.1 Introduction . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 75
9.2 Write Data to a File . . . . . . . . . . . . . . . . . . . . . . . . . 75
9.3 Read Data from a File . . . . . . . . . . . . . . . . . . . . . . . . 76
9.4 Logging Data to File . . . . . . . . . . . . . . . . . . . . . . . . . 76
9.5 Web Resources . . . . . . . . . . . . . . . . . . . . . . . . . . . . 77
9.6 Exercises . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 77
8

10 Error Handling in Python 80
10.1 Introduction to Error Handling . . . . . . . . . . . . . . . . . . . 80
10.1.1 Syntax Errors . . . . . . . . . . . . . . . . . . . . . . . . . 80
10.1.2 Exceptions . . . . . . . . . . . . . . . . . . . . . . . . . . 80
10.2 Exceptions Handling . . . . . . . . . . . . . . . . . . . . . . . . . 81
11 Debugging in Python 83
12 Installing and using Python Packages 84
12.1 What is PIP? . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 84
III Python Environments and Distributions 85
13 Introduction to Python Environments and Distributions 86
13.1 Package and Environment Managers . . . . . . . . . . . . . . . . 87
13.1.1 PIP . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 87
13.1.2 Conda . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 87
13.2 Python Virtual Environments . . . . . . . . . . . . . . . . . . . . 88
14 Anaconda 89
14.1 Anaconda Navigator . . . . . . . . . . . . . . . . . . . . . . . . . 89
14.2 Anaconda Prompt . . . . . . . . . . . . . . . . . . . . . . . . . . 89
15 Enthought Canopy 92
IV Python Editors 93
16 Python Editors 94
17 Spyder 96
17.1 Configuration . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 97
18 Visual Studio Code 99
18.1 Introduction to Visual Studio Code . . . . . . . . . . . . . . . . . 99
18.2 Python in Visual Studio Code . . . . . . . . . . . . . . . . . . . . 100
19 Visual Studio 101
19.1 Introduction to Visual Studio . . . . . . . . . . . . . . . . . . . . 101
19.2 Work with Python in Visual Studio. . . . . . . . . . . . . . . . . 101
19.2.1 Make Visual Studio ready for Python Programming . . . 102
19.2.2 Python Interactive . . . . . . . . . . . . . . . . . . . . . . 102
19.2.3 New Python Project . . . . . . . . . . . . . . . . . . . . . 103
20 PyCharm 109
21 Wing Python IDE 111
22 Jupyter Notebook 113
22.1 JupyterHub . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 114
22.2 Microsoft Azure Notebooks . . . . . . . . . . . . . . . . . . . . . 114
9

| V              | Python | for Mathematics |        | Applications |     |     | 116 |
| -------------- | ------ | --------------- | ------ | ------------ | --- | --- | --- |
| 23 Mathematics |        | in              | Python |              |     |     | 117 |
23.1 Basic Math Functions . . . . . . . . . . . . . . . . . . . . . . . . 117
|     | 23.1.1 | Exercises | . . . . | . . . . . . . | . . . . . . . | . . . . . . | . . . 119 |
| --- | ------ | --------- | ------- | ------------- | ------------- | ----------- | --------- |
23.2 Statistics . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 121
|     | 23.2.1 | Introduction | to Statistics | . .       | . . . . . . . | . . . . . . | . . . 121 |
| --- | ------ | ------------ | ------------- | --------- | ------------- | ----------- | --------- |
|     | 23.2.2 | Statistics   | functions     | in Python | . . . . . . . | . . . . . . | . . . 122 |
23.3 Trigonometric Functions . . . . . . . . . . . . . . . . . . . . . . . 124
23.4 Polynomials . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 128
| VI        | Resources |           |     |     |     |     | 131 |
| --------- | --------- | --------- | --- | --- | --- | --- | --- |
| 24 Python |           | Resources |     |     |     |     | 132 |
24.1 Python Distributions . . . . . . . . . . . . . . . . . . . . . . . . . 132
24.2 Python Libraries . . . . . . . . . . . . . . . . . . . . . . . . . . . 132
24.3 Python Editors . . . . . . . . . . . . . . . . . . . . . . . . . . . . 132
24.4 Python Tutorials . . . . . . . . . . . . . . . . . . . . . . . . . . . 133
24.5 Python in Visual Studio . . . . . . . . . . . . . . . . . . . . . . . 133
| VII | Solutions | to  | Exercises |     |     |     | 136 |
| --- | --------- | --- | --------- | --- | --- | --- | --- |
10

Part I
| Getting | Started | with |
| ------- | ------- | ---- |
Python
11

| Chapter | 1   |     |     |     |
| ------- | --- | --- | --- | --- |
Introduction
With this textbook you will learn basic Python programming. The textbook
contains lots of examples and self-paced tasks that the users should go through
| and solve | in their own pace. |                 |          |           |
| --------- | ------------------ | --------------- | -------- | --------- |
| You will  | find additional    | resources on my | blog/web | site [1]. |
https://www.halvorsen.blog
| My Web | Site about Python | is: |     |     |
| ------ | ----------------- | --- | --- | --- |
https://www.halvorsen.blog/documents/programming/python/
| See Figure | 1.1     |                    |     |     |
| ---------- | ------- | ------------------ | --- | --- |
| 1.1        | The New | Age of Programming |     |     |
The way we create software today has changed dramatically the last 30 years,
from the childhood of personal computers in the early 80s to today’s powerful
| devices | such as Smartphones, | Tablets | and PCs. |     |
| ------- | -------------------- | ------- | -------- | --- |
The Internet has also changed the way we use devices and software. We still
havetraditionaldesktopapplications, butWebSites, WebApplicationsandso-
called Apps for Smartphones, etc. are dominating the software market today.
We need to find and learn Programming Languages that are suitable for the
| New Age | of Programming. |     |     |     |
| ------- | --------------- | --- | --- | --- |
We have today several thousand different Programming Languages, so why
should we learn Python? I guess you will need to learn more than one Pro-
gramming Language to survive in today’s software market. Python is easy to
| learn, so | it it a good starting | point for | new programmers. |     |
| --------- | --------------------- | --------- | ---------------- | --- |
Python is an interpreted, high-level, general-purpose programming language.
| Created | by Guido van Rossum | and first | released | in 1991 [2]. |
| ------- | ------------------- | --------- | -------- | ------------ |
12

|     |     | Figure 1.1: | Web Site - | Python |
| --- | --- | ----------- | ---------- | ------ |
Python is a fairly old Programming Language (1991) compared to many other
ProgrammingLanguageslikeC#(2000),Swift(2014),Java(1995),PHP(1995).
Python has during the last 10 years become more and more popular. Today,
| Python | has become | one of the most | popular Programming | Languages. |
| ------ | ---------- | --------------- | ------------------- | ---------- |
Therearemanydifferentrankingsregardingwhichprogramminglanguagewhich
| is most | popular. In | most of these | ranking, Python | is in top 10. |
| ------- | ----------- | ------------- | --------------- | ------------- |
One of these rankings is the IEEE Spectrum’s ranking of the top programming
| languages | [3]. |     |     |     |
| --------- | ---- | --- | --- | --- |
From this ranking we see that Python is the most popular Programming Lan-
| guage in | 2018. See Figure | 1.2 |     |     |
| -------- | ---------------- | --- | --- | --- |
As we see in Figure 1.2 they categorize the different Programming Languages
| into the | following categories: |     |     |     |
| -------- | --------------------- | --- | --- | --- |
• Web
13

|     | Figure | 1.2: The Most | Popular | Programming | Languages |     |
| --- | ------ | ------------- | ------- | ----------- | --------- | --- |
• Mobile
• Enterprise
• Embedded
According to Figure 1.2 we see that Python can be used to program Web Ap-
| plications, | Enterprise | Applications | and | Embedded | Applications. |     |
| ----------- | ---------- | ------------ | --- | -------- | ------------- | --- |
SofarPythonisnotusedornotoptimizedforcreatingMobileApplications. We
havetoday2majorMobileplatforms;iOSApplicationsaremainlyprogrammed
with the Swift Programming language, while Android Applications are mainly
| programmed | with | either Java | or Kotlin. |     |     |     |
| ---------- | ---- | ----------- | ---------- | --- | --- | --- |
Another survey is the ”Stack Overflow Developer Survey 2018” [4]. See Figure
1.3.
Aswecanseefrom[5]andFigure1.4, Pythonbecomesmoreandmorepopular
year by year.
Based on Figure 1.4, the source [5] try to predict the future of Python, see
Figure 1.5.
Based on the surveys and statistics mention above, obviously Python is a pro-
| gramming | language | that you should | learn. |     |     |     |
| -------- | -------- | --------------- | ------ | --- | --- | --- |
Lets summarize:
•
| Python | is    | fun to learn | and use | and it | is also named | after the British |
| ------ | ----- | ------------ | ------- | ------ | ------------- | ----------------- |
| comedy | group | called Monty | Python. |        |               |                   |
• Python has a simple and flexible code structure and the code is easy to
read.
14

Figure 1.3: The Top Programming Languages - Stack Overflow Survey
• Python is highly extendable due to its high number of free available
Python Packaged and Libraries
• Python can be used on all platforms (Windows, macOS and Linux).
• Pythonismulti-purposeandcanbeusedfortoprogramWebApplications,
Enterprise Applications and Embedded Applications, and within Data
Science and Engineering Applications.
• The popularity of Python is growing fast.
• Python is open source and free to use
• The growing Python community makes it easy to find documentation,
code examples and get help when needed
In general, Python is a multipurpose programming language that can be used
in many situations. But there is not one programming language which is best
in all kind of situations, so it is important that you know about and have skills
in different languages.
My list of recommendations (one of many):
• Visual Studio and C
• LabVIEW - a graphical programming language well suited for hardware
integration, taking measurements and data logging
• MATLAB - Numerical calculations and Scientific computing
• Python - Numerical calculations, and Scientific computing, etc.
• Web Programming, such as HTML, CSS, JavaScript and a Server-side
framework/programming language like PHP, ASP.NET (C or VB.NET),
Django (Python based)
15

|     | Figure | 1.4: | The Incredible |     | Growth | of Python |     |     |
| --- | ------ | ---- | -------------- | --- | ------ | --------- | --- | --- |
• Databases (such as SQL Server and MySQL) and using the Structured
| Query | Language | (SQL) | or the | upcoming | NoSQL | databases |     |     |
| ----- | -------- | ----- | ------ | -------- | ----- | --------- | --- | --- |
•
| App Development |     | for       | the 2 main | platforms   |          | iOS (XCode | using | the Swift |
| --------------- | --- | --------- | ---------- | ----------- | -------- | ---------- | ----- | --------- |
| Programming     |     | Language) | and        | Android     | (Android | Studio     | using | the Java  |
| Programming     |     | Language  | or Kotlin  | Programming |          | language)  |       |           |
If you have skills in most of the tools, programming languages and frameworks
mention above, you are well suited for working as a full-time programmer or
software engineer.
1.2 MATLAB
| If you are looking |     | for MATLAB, | please | see | the following: |     |     |     |
| ------------------ | --- | ----------- | ------ | --- | -------------- | --- | --- | --- |
https://www.halvorsen.blog/documents/programming/matlab/
16

| Figure | 1.5: The Future | of Python |
| ------ | --------------- | --------- |
17

| Chapter | 2            |           |     |
| ------- | ------------ | --------- | --- |
| What    | is           | Python?   |     |
| 2.1     | Introduction | to Python |     |
Python is an open source and cross-platform programming language, that has
become increasingly popular over the last ten years. It was first released in
1991. Latest version is 3.7.0. CPython is the reference implementation of the
Pythonprogramminglanguage. WritteninC,CPythonisthedefaultandmost
| widely-used | implementation | of the language. |     |
| ----------- | -------------- | ---------------- | --- |
Pythonisamulti-purposeprogramminglanguages(duetoitsmanyextensions),
examples are scientific computing and calculations, simulations, web develop-
| ment (using, | e.g., the Django | Web framework), | etc. |
| ------------ | ---------------- | --------------- | ---- |
| Python       | Home Page [6]:   |                 |      |
https://www.python.org
The programming language is maintained and available from (Python Software
Foundation): https://www.python.orgHereyoucandownloadthebasicPython
features in one package, which includes the Python programming language in-
terpreter, and a basic code editor, or an integrated development environment,
| called IDLE. | See Figure | 2.1 |     |
| ------------ | ---------- | --- | --- |
ButthisisjustthePythoncore, i.e. theinterpreteraverybasiceditor, andthe
| minimum | needed to create | basic Python programs. |     |
| ------- | ---------------- | ---------------------- | --- |
Typically you will need more features for solving your tasks. Then you can in-
stallanduseseparatePythonpackagescreatedbythirdparties. Thesepackages
need to be downloaded and installed separately (typically you use something
called PIP), or you choose to use, e.g., a distribution package like Anaconda.
Python is an object-oriented programming language (OOP), but you can use
Python in basic application without the need to know about or use the object-
| oriented | features in Python. |     |     |
| -------- | ------------------- | --- | --- |
Pythonisaninterpretedprogramminglanguage,thismeansthatasadeveloper
18

|     | Figure | 2.1: IDLE | - Basic | Python | Editor |
| --- | ------ | --------- | ------- | ------ | ------ |
you write Python (.py) files in a text editor and then put those files into the
python interpreter to be executed. Depending on the Editor you are using, this
| is either done    | automatically, | or you          | need to | do it manually. |      |
| ----------------- | -------------- | --------------- | ------- | --------------- | ---- |
| Here are some     | important      | Python sources: |         | [6], [7],       | [8]. |
| 2.1.1 Interpreted |                | vs. Compiled    |         |                 |      |
WhatarethedifferencesbetweenInterpretedprogramminglanguagesandCom-
piled programming languages? What kind should you choose, and why should
you bother?
Programming languages generally fall into one of two categories: Compiled or
Interpreted. With a compiled language, code you enter is reduced to a set of
| machine-specific | instructions | before     | being | saved as       | an executable file. |
| ---------------- | ------------ | ---------- | ----- | -------------- | ------------------- |
| Both approaches  | have their   | advantages | and   | disadvantages. |                     |
19

With interpreted languages, the code is saved in the same format that you en-
tered. Compiled programs generally run faster than interpreted ones because
interpreted programs must be reduced to machine instructions at run-time. It
is usually easier to develop applications in an interpreted environment because
youdon’thavetorecompileyourapplicationeachtimeyouwanttotestasmall
section.
Python is an interpreted programming language, while e.g., C/C++ are trans-
latedbyrunningthesourcecodethroughacompiler, i.e., C/C++arecompiled
languages.
Interpreted languages, in contrast, must be parsed, interpreted, and executed
each time the program is run.
Another example of an interpreted programming language is PHP, which is
mainly used to create dynamic web pages and web applications.
Compiled languages are all translated by running the source code through a
compiler. Thisresultsinveryefficientcodethatcanbeexecutedanynumberof
times. The overhead for the translation is incurred just once, when the source
is compiled; thereafter, it need only be loaded and executed.
During the design of an application, you might need to decide whether to use a
compiled language or an interpreted language for the application source code.
Interpreted languages, in contrast, must be parsed, interpreted, and executed
each time the program is run
Thus, an interpreted language is generally more suited for doing ”ad hoc” cal-
culations or simulations, while compiled languages are better for permanent
applications where speed is in focus.
2.2 Python Packages
With Python you don’t get so much out of the box. Instead of having all of
its functionality built into its core, you need to install different packages for
different topics.
This approach has advantages and disadvantages. An disadvantage is that you
need to install these packages separately and then later import these modules
in your code.
This is also typical approach for open source software, because everybody can
create their own Python packages and distribute them. In that way you also
find Python packages for almost everything, from Scientific Computing to Web
Development.
20

These packages need to be downloaded and installed separately, or you choose
to use, e.g., a distribution package like Anaconda, where you typically get the
packages you need for scientific computing. With Anaconda you typically get
| the same | features | as       | with MATLAB. |           |     |         |                  |        |
| -------- | -------- | -------- | ------------ | --------- | --- | ------- | ---------------- | ------ |
| Lots of  | Python   | packages | exists,      | depending |     | on what | you are going to | solve. |
We have Python packages for Desktop GUI Development, Database Develop-
| ment, Web | Development, |                 | Software |     | Development, | etc. |     |     |
| --------- | ------------ | --------------- | -------- | --- | ------------ | ---- | --- | --- |
| See an    | overview     | of Applications |          | for | Python:      |      |     |     |
https://www.python.org/about/apps/
| See also | the Python | Package |     | Index | (PyPI) | web site: |     |     |
| -------- | ---------- | ------- | --- | ----- | ------ | --------- | --- | --- |
https://pypi.org
Here you can search for, download and install many hundreds Python Packages
within different topics and applications. You can also make your own Python
| Packages | and distribute |          | them | here. |         |     |           |      |
| -------- | -------------- | -------- | ---- | ----- | ------- | --- | --------- | ---- |
| 2.2.1    | Python         | Packages |      | for   | Science | and | Numerical | Com- |
putations
SomeimportantPythonPackagesforScienceandNumericalComputationsare:
• NumPy - NumPy is the fundamental package for scientific computing
| with | Python | [9] |     |     |     |     |     |     |
| ---- | ------ | --- | --- | --- | --- | --- | --- | --- |
•
| SciPy                           | -   | SciPy | is a free | and open-source |     | Python                           | library used for | scientific |
| ------------------------------- | --- | ----- | --------- | --------------- | --- | -------------------------------- | ---------------- | ---------- |
| computingandtechnicalcomputing. |     |       |           |                 |     | SciPycontainsmodulesforoptimiza- |                  |            |
tion,linearalgebra,integration,interpolation,specialfunctions,FFT,sig-
nalandimageprocessing,ODEsolversandothertaskscommoninscience
| and          | engineering. |              | [9]    |      |          |             |               |     |
| ------------ | ------------ | ------------ | ------ | ---- | -------- | ----------- | ------------- | --- |
| • Matplotlib |              | - Matplotlib |        | is a | Python   | 2D plotting | library. [10] |     |
| • Pandas     |              | - Pandas     | Python | Data | Analysis | Library     | [11]          |     |
These packages need to be downloaded and installed separately, or you choose
to use, e.g., a distribution package like Anaconda, where you typically get the
packages you need for scientific computing. With Anaconda you typically get
| the same | features | as  | with MATLAB. |     |     |     |     |     |
| -------- | -------- | --- | ------------ | --- | --- | --- | --- | --- |
2.3 Anaconda
Anaconda is a distribution package, where you get Python compiler, Python
| packages | and the | Spyder | editor, | all | in one | package. |     |     |
| -------- | ------- | ------ | ------- | --- | ------ | -------- | --- | --- |
Anaconda includes Python, the Jupyter Notebook, and other commonly used
| packages | for scientific |     | computing | and | data | science. |     |     |
| -------- | -------------- | --- | --------- | --- | ---- | -------- | --- | --- |
21

They offer a free version (Anaconda Distribution) and a paid version (Enter-
| prise) Anaconda | is available | for Windows, | macOS, | and Linux |
| --------------- | ------------ | ------------ | ------ | --------- |
Web:
https://www.anaconda.com
Wikipedia:
| https://en.wikipedia.org/wiki/Anaconda |     |     | Python istribution) |     |
| -------------------------------------- | --- | --- | ------------------- | --- |
( d
SpyderandthePythonpackages(NumPy,SciPy,Matplotlib,...) mentionabove
| +++ are included | in the  | Anaconda Distribution. |     |     |
| ---------------- | ------- | ---------------------- | --- | --- |
| 2.4 Python       | Editors |                        |     |     |
An Editor is a program where you create your code (and where you can run
and test it). Most Editors have also features for Debugging. For simple Python
programsyoucanusetheIDLEEditor, butformoreadvancedprogramsabet-
| ter editor is recommended. |                 |     |     |     |
| -------------------------- | --------------- | --- | --- | --- |
| Examples of                | Python Editors: |     |     |     |
•
| Python   | IDLE        |     |     |     |
| -------- | ----------- | --- | --- | --- |
| • Visual | Studio Code |     |     |     |
• Thonny
• Spyder
| • Visual | Studio |     |     |     |
| -------- | ------ | --- | --- | --- |
• PyCharm
•
| Wing Python | IDE |     |     |     |
| ----------- | --- | --- | --- | --- |
•
| Jupyter | Notebook |     |     |     |
| ------- | -------- | --- | --- | --- |
These editors are shortly described below and in more detail later in this text-
book.
Which editor you should use depends on your background, what kind of code
editors you have used previously, your programming skills, what your are going
| to develop in | Python, etc. |     |     |     |
| ------------- | ------------ | --- | --- | --- |
| 2.4.1 Python  | IDLE         |     |     |     |
The programming language is maintained and available from (Python Software
Foundation): https://www.python.orgHereyoucandownloadthebasicPython
features in one package, which includes the Python programming language in-
terpreter, and a basic code editor, or an integrated development environment,
| called IDLE. | See Figure | 2.1 |     |     |
| ------------ | ---------- | --- | --- | --- |
22

Web:
https://www.python.org
| 2.4.2 | Visual | Studio | Code |     |     |     |     |
| ----- | ------ | ------ | ---- | --- | --- | --- | --- |
VisualStudioCodeisasourcecodeeditordevelopedbyMicrosoftforWindows,
| Linux and | macOS. |     |     |     |     |     |     |
| --------- | ------ | --- | --- | --- | --- | --- | --- |
Web:
https://code.visualstudio.com
| Resources: | Getting | Started | with | Python | in  | Visual Studio | Code |
| ---------- | ------- | ------- | ---- | ------ | --- | ------------- | ---- |
| 2.4.3      | Thonny  |         |      |        |     |               |      |
Thonny is a Python IDE for beginners. Thonny is a very simple and ba-
sic Python editor which is highly recommended for new Python users. With
Thonny you can easily install Python Libraries/Packages using a Graphical
User Interface without the need of using more cryptic PIP commands in the
| Command | window/Terminal. |             |        |        |     |               |        |
| ------- | ---------------- | ----------- | ------ | ------ | --- | ------------- | ------ |
| Thonny  | is also          | the default | Python | Editor | on  | the Raspberry | Pi OS. |
Web: https://thonny.org
| Wikipedia: | https://en.wikipedia.org/wiki/Thonny |     |     |     |     |     |     |
| ---------- | ------------------------------------ | --- | --- | --- | --- | --- | --- |
| 2.4.4      | Spyder                               |     |     |     |     |     |     |
Spyder is an open source cross-platform integrated development environment
| (IDE) for | scientific | programming |     | in the | Python | language. |     |
| --------- | ---------- | ----------- | --- | ------ | ------ | --------- | --- |
Web:
https://www.spyder-ide.org
Wikipedia:
| https://en.wikipedia.org/wiki/Spyder |     |     |     |     | software) |     |     |
| ------------------------------------ | --- | --- | --- | --- | --------- | --- | --- |
(
| Spyder | is included | in     | the Anaconda | Distribution. |     |     |     |
| ------ | ----------- | ------ | ------------ | ------------- | --- | --- | --- |
| 2.4.5  | Visual      | Studio |              |               |     |     |     |
Microsoft Visual Studio is an integrated development environment (IDE) from
Microsoft. It is used to develop computer programs, as well as websites, web
apps,webservicesandmobileapps. Thedeafult(main)programminglanguage
in Visual studio is C, but many other programming languages are supported.
| Visual | studio is | available | for | Windows | and macOS. |     |     |
| ------ | --------- | --------- | --- | ------- | ---------- | --- | --- |
23

Visual Studio (from 2017), has integrated support for Python, it is called
| ”Python Support | in Visual Studio”. |     |     |     |
| --------------- | ------------------ | --- | --- | --- |
Web:
https://visualstudio.microsoft.com
Wikipedia:
| https://en.wikipedia.org/wiki/Microsoft |     | isual | tudio |     |
| --------------------------------------- | --- | ----- | ----- | --- |
|                                         |     | V     | S     |     |
| 2.4.6 PyCharm                           |     |       |       |     |
PyCharm is cross-platform, with Windows, macOS and Linux versions. The
Community Edition is free to use, while the Professional Edition (paid version)
| has some extra | features. |     |     |     |
| -------------- | --------- | --- | --- | --- |
Web:
https://www.jetbrains.com/pycharm/
| 2.4.7 Wing | Python IDE |     |     |     |
| ---------- | ---------- | --- | --- | --- |
The Wing Python IDE family of integrated development environments (IDEs)
fromWingwarewerecreatedspecificallyforthePythonprogramminglanguage.
| 3 different version | of Wing exists | [12]: |     |     |
| ------------------- | -------------- | ----- | --- | --- |
• Wing 101 – a very simplified free version, for teaching beginning pro-
grammers
• Wing Personal–freeversionthatomitssomefeatures,forstudentsand
hobbyists
•
| Wing Pro | – a full-featured | commercial | (paid) version, | for professional |
| -------- | ----------------- | ---------- | --------------- | ---------------- |
programmers
| 2.4.8 Jupyter | Notebook |     |     |     |
| ------------- | -------- | --- | --- | --- |
TheJupyterNotebookisanopen-sourcewebapplicationthatallowsyoutocre-
ate and share documents that contain live code, equations, visualizations and
text.
Web:
http://jupyter.org
Wikipedia:
| https://en.wikipedia.org/wiki/Project |     | J upyter |     |     |
| ------------------------------------- | --- | -------- | --- | --- |
24

2.5 Resources
| Here are | some     | useful | Python   | resources: |     |     |     |     |
| -------- | -------- | ------ | -------- | ---------- | --- | --- | --- | --- |
| • The    | official | Python | Tutorial |            |     |     |     |     |
- https://docs.python.org/3.7/tutorial/index.html
| • The | official | Python | Documentation |     |     |     |     |     |
| ----- | -------- | ------ | ------------- | --- | --- | --- | --- | --- |
- https://docs.python.org/3.7/index.html
•
| Python |     | Tutorial | (w3schools.com) |     | [13] |     |     |     |
| ------ | --- | -------- | --------------- | --- | ---- | --- | --- | --- |
- https://www.w3schools.com/python/
| 2.6 | Installing |     | Python |     |     |     |     |     |
| --- | ---------- | --- | ------ | --- | --- | --- | --- | --- |
The Python programming language is maintained and available from (Python
| Software | Foundation): |     |     |     |     |     |     |     |
| -------- | ------------ | --- | --- | --- | --- | --- | --- | --- |
https://www.python.org
HereyoucandownloadthebasicPythonfeaturesinonepackage,whichincludes
the Python programming language interpreter, and a basic code editor, or an
| integrated | development |             | environment, |      | called  | IDLE.   | See Figure | 2.1 |
| ---------- | ----------- | ----------- | ------------ | ---- | ------- | ------- | ---------- | --- |
| For basic  | Python      | programming |              | this | is good | enough. |            |     |
For more advanced Python Programming you typically need a better Code Ed-
| itor and | additional |     | Packages. |     |     |     |     |     |
| -------- | ---------- | --- | --------- | --- | --- | --- | --- | --- |
For the basic Python examples in the beginning, the basic Python software
from:
| https://www.python.org |     |     | is  | good enough. |     |     |     |     |
| ---------------------- | --- | --- | --- | ------------ | --- | --- | --- | --- |
I suggest you start with the basic Python software in order to learn the basics,
thenyoucanupgradetoabetterEditor,installadditionPythonpackages(either
| manually | or or  | install        | Anaconda | where  | ”everything” |       | is included). |     |
| -------- | ------ | -------------- | -------- | ------ | ------------ | ----- | ------------- | --- |
| 2.6.1    | Python |                | Windows  |        | 10 Store     | App   |               |     |
| Python   | 3.7 is | also available |          | in the | Microsoft    | Store | for Windows   | 10. |
The Microsoft Store version of Python 3.7 is a simplified installer for running
| scripts | and packages. |     |     |     |     |     |     |     |
| ------- | ------------- | --- | --- | --- | --- | --- | --- | --- |
Microsoft Store version of Python 3.7 is very basic but it’s good enough to run
| the simple | scripts. |     |     |     |     |     |     |     |
| ---------- | -------- | --- | --- | --- | --- | --- | --- | --- |
Python 3.7 Microsoft Store edition will receive all updates automatically when
| they are | released | and | no manual | action |     | is required | from your | end. |
| -------- | -------- | --- | --------- | ------ | --- | ----------- | --------- | ---- |
25

In order to install the Microsoft Store version of Python just open Microsoft
| Store in | Windows    | 10  | and search | for Python. |     |
| -------- | ---------- | --- | ---------- | ----------- | --- |
| 2.6.2    | Installing |     | Anaconda   |             |     |
TheSpyderCodeEditorandthePythonpackages(suchasNumPy,SciPy,mat-
| plotlib, | etc) are | included | in the | Anaconda | Distribution. |
| -------- | -------- | -------- | ------ | -------- | ------------- |
| Download | and      | install  | from:  |          |               |
https://www.anaconda.com
| 2.6.3 | Installing |     | Visual | Studio | Code |
| ----- | ---------- | --- | ------ | ------ | ---- |
Visual Studio Code code is a simple and easy to use editor that can be used for
| many different |     | programming |       | languages. |     |
| -------------- | --- | ----------- | ----- | ---------- | --- |
| Download       | and | install     | from: |            |     |
https://code.visualstudio.com
| Getting | Started | with | Python | in Visual | Studio Code: |
| ------- | ------- | ---- | ------ | --------- | ------------ |
https://code.visualstudio.com/docs/python/python-tutorial
26

| Chapter         | 3       |                     |                |           |
| --------------- | ------- | ------------------- | -------------- | --------- |
| Start           | using   | Python              |                |           |
| In this chapter | we will | start to use Python | in some simple | examples. |
| 3.1 Python      | IDE     |                     |                |           |
The basic code editor, or an integrated development environment, called IDLE.
| See Figure | 3.1. |     |     |     |
| ---------- | ---- | --- | --- | --- |
Other Python Editors will be discussed more in detail later. For now you can
usethebasicPythonIDE(IDLE)orSpyderifyouhaveinstalledtheAnaconda
| distribution  | package.     |                   |                     |        |
| ------------- | ------------ | ----------------- | ------------------- | ------ |
|               | Figure       | 3.1: Python Shell | / Python IDLE       | Editor |
| 3.2 My        | first        | Python program    |                     |        |
| We will start | using Python | and create        | some code examples. |        |
27

| Example      | 3.2.1. Plotting |        | in Python |      |                |     |
| ------------ | --------------- | ------ | --------- | ---- | -------------- | --- |
| Lets open    | your Python     | Editor | and       | type | the following: |     |
| print(”Hello | World!”)        |        |           |      |                |     |
1
|     | Listing |     | 3.1: Hello | World | Python | Example |
| --- | ------- | --- | ---------- | ----- | ------ | ------- |
[End of Example]
An extremely useful command is help(), which enters a help functionality to
explore all the stuff python lets you do, right from the interpreter. Press q to
| close the | help window | and | return | to the | Python | prompt. |
| --------- | ----------- | --- | ------ | ------ | ------ | ------- |
YoucanusePythonindifferentways,eitherin”interactive”modeorin”Script-
ing” mode.
The python program that you have installed will by default act as something
called an interpreter. An interpreter takes text commands and runs them as
| you enter | them - very | handy | for | trying | things out. |     |
| --------- | ----------- | ----- | --- | ------ | ----------- | --- |
YocanrunPythoninteractivelyindifferentwayseitherusingtheConsolewhich
ispartoftheoperatingsystemorthePythonIDLEandthePythonShellwhich
| is part of     | the basic | Python  | installation |        | from https://www.python.org. |                     |
| -------------- | --------- | ------- | ------------ | ------ | ---------------------------- | ------------------- |
| 3.3 Python     |           | Shell   |              |        |                              |                     |
| In interactive | Mode      | you use | the          | Python | Shell as                     | seen in Figure 3.1. |
Here you type one and one command at a time after the ”>>>” sign in the
Python Shell.
| 1 >>> print(”Hello |     | World!”) |     |      |     |         |
| ------------------ | --- | -------- | --- | ---- | --- | ------- |
| 3.4 Running        |     | Python   |     | from | the | Console |
A console (or ”terminal”, or ‘command prompt’) is a textual way to interact
| with your | OS (Operating |     | System). |     |     |     |
| --------- | ------------- | --- | -------- | --- | --- | --- |
The python program that you have installed will by default act as something
called an interpreter. An interpreter takes text commands and runs them as
| you enter | them - very | handy | for | trying | things out. |     |
| --------- | ----------- | ----- | --- | ------ | ----------- | --- |
BelowweseehowwecanrunPythonfromtheConsolewhichispartoftheOS.
28

| 3.4.1 | Opening |     | the | Console | on  | macOS |     |     |
| ----- | ------- | --- | --- | ------- | --- | ----- | --- | --- |
The standard console on macOS is a program called Terminal. Open Terminal
bynavigatingtoApplications,thenUtilities,thendouble-clicktheTerminalpro-
gram. Youcanalsoeasilysearchforitinthesystemsearchtoolinthetopright.
The command line Terminal is a tool for interacting with your computer. A
window will open with a command line prompt message, something like this:
| Last login:    |     | Tue Dec  | 11  | 08:33:51 | on  | console |     |     |
| -------------- | --- | -------- | --- | -------- | --- | ------- | --- | --- |
| computername:˜ |     | username |     |          |     |         |     |     |
Just type python at your console, hit Enter, and you should enter Python’s
Interpreter.
| Last login: |     | Tue Dec | 11  | 12:34:16 | on  | ttys000 |     |     |
| ----------- | --- | ------- | --- | -------- | --- | ------- | --- | --- |
1
| Hans−Petter−Work−MacBook−Air:˜ |     |     |     |     | hansha$ | python |     |     |
| ------------------------------ | --- | --- | --- | --- | ------- | ------ | --- | --- |
2
| Python | 3.6.5 | |Anaconda, |     | Inc.| | (default | , Apr 26 | 2018, 08:42:37) |     |
| ------ | ----- | ---------- | --- | ----- | -------- | -------- | --------------- | --- |
3
| 4 [GCC 4.2.1 | Compatible |     | Clang | 4.0.1 | (tags/RELEASE |     | 401/final)] | on  |
| ------------ | ---------- | --- | ----- | ----- | ------------- | --- | ----------- | --- |
darwin
| 5 Type ”help”, |     | ”copyright”, |     | ”credits” |     | or ”license” | for more |     |
| -------------- | --- | ------------ | --- | --------- | --- | ------------ | -------- | --- |
information.
6 >>>
The prompt >>> on the last line indicates that you are now in an interactive
Python interpeter session, also called the “Python shell”. This is different from
| the normal       | terminal  |           | command | prompt!    |         |              |     |     |
| ---------------- | --------- | --------- | ------- | ---------- | ------- | ------------ | --- | --- |
| You can          | now enter | some      | code    | for python |         | to run. Try: |     |     |
| >>> print(”Hello |           | World”)   |         |            |         |              |     |     |
| Se also          | Figure    | 3.2.      |         |            |         |              |     |     |
|                  |           |           | Figure  | 3.2:       | Console | macOS        |     |     |
| Try other        | Python    | commands, |         | e.g.:      |         |              |     |     |
| >>> a =          | 5         |           |         |            |         |              |     |     |
1
| >>> b = | 2   |     |     |     |     |     |     |     |
| ------- | --- | --- | --- | --- | --- | --- | --- | --- |
2
| >>> x = | 5   |     |     |     |     |     |     |     |
| ------- | --- | --- | --- | --- | --- | --- | --- | --- |
3
| >>> y = | 3∗a | + b |     |     |     |     |     |     |
| ------- | --- | --- | --- | --- | --- | --- | --- | --- |
4
>>> y
5
29

| 3.4.2 | Opening |     | the Console | on  | Windows |     |
| ----- | ------- | --- | ----------- | --- | ------- | --- |
Window’sconsoleiscalledtheCommandPrompt,namedcmd. Aneasywayto
get to it is by using the key combination Windows+R (Windows meaning the
windows logo button), which should open a Run dialog. Then type cmd and
| hit Enter | or click    | Ok.   |             |       |       |     |
| --------- | ----------- | ----- | ----------- | ----- | ----- | --- |
| You can   | also search | for   | it from the | start | menu. |     |
| It should | look        | like: |             |       |       |     |
C:\Users\myusername>
Just type python in the Command Prompt, hit Enter, and you should enter
| Python’s   | Interpreter. |         | See Figure 3.3. |     |                |     |
| ---------- | ------------ | ------- | --------------- | --- | -------------- | --- |
|            |              | Figure  | 3.3: Command    |     | Prompt Windows |     |
| If you get | an error     | message | like this:      |     |                |     |
’python’isnotrecognizedasaninternalorexternalcommand,operableprogram
or batch file.
| Then you | need | to add | Python to your | path. | See instructions | below. |
| -------- | ---- | ------ | -------------- | ----- | ---------------- | ------ |
Note! This is also an option during the setup. While installing you can se-
lect ”Add Python.exe to path”. This option is by default set to ”Off”. To get
thatoptionyouneedtoselect”Customize”,notusingthe”Default”installation.
| 3.4.3 | Add | Python | to Path |     |     |     |
| ----- | --- | ------ | ------- | --- | --- | --- |
In the Windows menu, search for “advanced system settings” and select View
| advanced | system | settings. |     |     |     |     |
| -------- | ------ | --------- | --- | --- | --- | --- |
In the window that appears, click Environment Variables... near the bottom
| right. See | Figure | 3.4. |     |     |     |     |
| ---------- | ------ | ---- | --- | --- | --- | --- |
30

|     | Figure | 3.4: Windows System | Properties |
| --- | ------ | ------------------- | ---------- |
In the next window, find and select the user variable named Path and click
| Edit... to change | its value. | See Figure 3.5. |     |
| ----------------- | ---------- | --------------- | --- |
Select ”New” and add the path where ”python.exe” is located. See Figure 3.6.
| The Default Location | is: |     |     |
| -------------------- | --- | --- | --- |
C:\Users\user\AppData\Local\Programs\Python\Python37−32\
Click Save and open the Command Prompt once more and enter ”python” to
| verify it works. | See Figure | 3.3. |     |
| ---------------- | ---------- | ---- | --- |
31

|     |           | Figure | 3.5: Windows | System | Properties |
| --- | --------- | ------ | ------------ | ------ | ---------- |
| 3.5 | Scripting |        | Mode         |        |            |
In ”Scripting” mode you can write a Python Program with multiple Python
| commands | and | then save | it as a | file (.py). |                 |
| -------- | --- | --------- | ------- | ----------- | --------------- |
| 3.5.1    | Run | Python    | Scripts | from        | the Python IDLE |
From the Python Shell you select File → New File, or you can open an existing
| Pytho program |       | or Python | Script   | by selecting      | File → Open... |
| ------------- | ----- | --------- | -------- | ----------------- | -------------- |
| Lets create   | a new | Script    | and type | in the following: |                |
1 print(”Hello”)
2 print(”World”)
| 3 print(”How | are | you?”) |     |     |     |
| ------------ | --- | ------ | --- | --- | --- |
In Figure 3.7 we see how this is done. As you see we can enter many Python
| commands | that | together | makes a | Python | program or Python script. |
| -------- | ---- | -------- | ------- | ------ | ------------------------- |
FromthePythonShellyouselectRun→RunModuleorhitF5inordertorun
| or execute | the | Python Script. | See | Figure | 3.8. |
| ---------- | --- | -------------- | --- | ------ | ---- |
32

|     |     | Figure | 3.6: Windows | System | Properties |     |     |
| --- | --- | ------ | ------------ | ------ | ---------- | --- | --- |
The IDLE editor is very basic, for more complicated tasks you typically may
| prefer to | use another | editor | like Spyder, | Visual | Studio | Code,   | etc.       |
| --------- | ----------- | ------ | ------------ | ------ | ------ | ------- | ---------- |
| 3.5.2     | Run         | Python | Scripts      | from   | the    | Console | (Terminal) |
macOS
| From the | Console | (Terminal) | on macOS: |     |     |     |     |
| -------- | ------- | ---------- | --------- | --- | --- | --- | --- |
$
1 cd /Users/username/Downloads
$
| 2 python | helloworld.py |     |     |     |     |     |     |
| -------- | ------------- | --- | --- | --- | --- | --- | --- |
Note! Make sure you are at your system command prompt, which will have $
| or > at  | the end, | not in | Python mode | (which | has >>> | instead)! |     |
| -------- | -------- | ------ | ----------- | ------ | ------- | --------- | --- |
| See also | Figure   | 3.9.   |             |        |         |           |     |
| Then it  | responds | with:  |             |        |         |           |     |
1 Hello
2 World
| How are | you? |     |     |     |     |     |     |
| ------- | ---- | --- | --- | --- | --- | --- | --- |
3
33

|       |            | Figure  | 3.7: Python | Script  |           |
| ----- | ---------- | ------- | ----------- | ------- | --------- |
| 3.5.3 | Run Python | Scripts | from the    | Command | Prompt in |
Windows
| From Command | Prompt | in Window: |     |     |     |
| ------------ | ------ | ---------- | --- | --- | --- |
1 > cd /
2 > cd Temp
| 3 > python | helloworld.py |     |     |     |     |
| ---------- | ------------- | --- | --- | --- | --- |
Note! Make sure you are at your system command prompt, which will have >
| at the end, | not in Python  | mode (which | has >>> | instead)! |     |
| ----------- | -------------- | ----------- | ------- | --------- | --- |
| See also    | Figure 3.10.   |             |         |           |     |
| Then it     | responds with: |             |         |           |     |
1 Hello
2 World
| 3 How are | you?       |         |             |     |     |
| --------- | ---------- | ------- | ----------- | --- | --- |
| 3.5.4     | Run Python | Scripts | from Spyder |     |     |
IfyouhaveinstalledtheAnacondadistributionpackageyoucanusetheSpyder
| editor. | See 3.11. |     |     |     |     |
| ------- | --------- | --- | --- | --- | --- |
In the Spyder editor we have the Script Editor to the left and the interactive
| Python | Shell or the Console | window | to the right. | See | See 3.11. |
| ------ | -------------------- | ------ | ------------- | --- | --------- |
34

|              | Figure              | 3.8: Running a | Python Script  |          |
| ------------ | ------------------- | -------------- | -------------- | -------- |
| Figure       | 3.9: Running Python | Scripts from   | Console window | on macOS |
| Figure 3.10: | Running Python      | Scripts from   | Console window | on macOS |
35

| Figure 3.11: | Running a Python | Script in Spyder |
| ------------ | ---------------- | ---------------- |
36

| Chapter      |           | 4            |            |          |                     |         |
| ------------ | --------- | ------------ | ---------- | -------- | ------------------- | ------- |
| Basic        |           | Python       |            |          | Programming         |         |
| 4.1          | Basic     | Python       |            | Program  |                     |         |
| We will      | start     | using Python | and        | create   | some code examples. |         |
| We use       | the basic | IDLE         | editor (or | another  | Python              | Editor) |
| Example      | 4.1.1.    | Hello        | World      | Example  |                     |         |
| Lets open    | your      | Python       | Editor     | and type | the following:      |         |
| print(”Hello |           | World!”)     |            |          |                     |         |
1
|     |     | Listing | 4.1: | Hello World | Python | Example |
| --- | --- | ------- | ---- | ----------- | ------ | ------- |
[End of Example]
| 4.1.1 | Get | Help |     |     |     |     |
| ----- | --- | ---- | --- | --- | --- | --- |
An extremely useful command is help(), which enters a help functionality to
| explore | all the  | stuff python | lets   | you do,    | right from | the interpreter. |
| ------- | -------- | ------------ | ------ | ---------- | ---------- | ---------------- |
| Press q | to close | the help     | window | and return | to the     | Python prompt.   |
4.2 Variables
Variablesaredefinedwiththeassignmentoperator,“=”. Pythonisdynamically
typed,meaningthatvariablescanbeassignedwithoutdeclaringtheirtype,and
thattheirtypecanchange. Valuescancomefromconstants, fromcomputation
| involving | values | of other | variables, | or  | from the output | of a function. |
| --------- | ------ | -------- | ---------- | --- | --------------- | -------------- |
37

| Example | 4.2.1. | Creating |     | and using | Variables | in Python |     |     |
| ------- | ------ | -------- | --- | --------- | --------- | --------- | --- | --- |
We use the basic IDLE (or another Python Editor) and type the following:
| 1 >>> x = | 3   |     |     |     |     |     |     |     |
| --------- | --- | --- | --- | --- | --- | --- | --- | --- |
2 >>> x
3 3
|     |     |     | Listing | 4.2: Using | Variables | in  | Python |     |
| --- | --- | --- | ------- | ---------- | --------- | --- | ------ | --- |
Herewedefineavariableandsetsthevalueequalto3andthenprinttheresult
to the screen.
|     |     |     |     |     |     |     | [End | of Example] |
| --- | --- | --- | --- | --- | --- | --- | ---- | ----------- |
YoucanwriteonecommandbytimeintheIDLE.IfyouquitIDLEthevariables
and data are lost. Therefore, if you want to write a somewhat longer program,
you are better off using a text editor to prepare the input for the interpreter
andrunningitwiththatfileasinputinstead. Thisisknownascreatingascript.
| Python  | scripts       | or programs  |                  | are save | as a   | text file with | the extension | .py |
| ------- | ------------- | ------------ | ---------------- | -------- | ------ | -------------- | ------------- | --- |
| Example | 4.2.2.        | Calculations |                  | in       | Python |                |               |     |
| We can  | use variables |              | in a calculation |          | like   | this:          |               |     |
1 x = 3
3∗x
2 y =
print(y)
3
|        | Listing   |     | 4.3: Using | and | Printing | Variables  | in Python |     |
| ------ | --------- | --- | ---------- | --- | -------- | ---------- | --------- | --- |
| We can | implement | the | formula    | y   | =ax+b    | like this: |           |     |
a = 2
1
2 b = 5
3 x = 3
4
a∗x
| 5 y = | + b |     |     |     |     |     |     |     |
| ----- | --- | --- | --- | --- | --- | --- | --- | --- |
6
print(y)
7
|     |     |     | Listing | 4.4: | Calculations | in Python |     |     |
| --- | --- | --- | ------- | ---- | ------------ | --------- | --- | --- |
Asseenintheexamples, youcanusetheprint() commandinordertoshowthe
| values on | the | screen. |     |     |     |     |      |             |
| --------- | --- | ------- | --- | --- | --- | --- | ---- | ----------- |
|           |     |         |     |     |     |     | [End | of Example] |
38

A variable can have a short name (like x and y) or a more descriptive name
| (sum, amount, | etc). |     |     |     |
| ------------- | ----- | --- | --- | --- |
You don need to define the variables before you use them (like you need to to
in, e.g., C/C++/C).
| Figure 4.1    | show these examples | using       | the basic IDLE | editor.                  |
| ------------- | ------------------- | ----------- | -------------- | ------------------------ |
|               |                     | Figure 4.1: | Basic Python   |                          |
| Here are some | basic rules         | for Python  | variables:     |                          |
| • A variable  | name must           | start with  | a letter or    | the underscore character |
| • A variable  | name cannot         | start with  | a number       |                          |
• Avariablenamecanonlycontainalpha-numericcharacters(A-z,0-9)and
underscores
• Variable names are case-sensitive, e.g., amount, Amount and AMOUNT
| are three     | different     | variables.       |     |     |
| ------------- | ------------- | ---------------- | --- | --- |
| 4.2.1 Numbers |               |                  |     |     |
| There are     | three numeric | types in Python: |     |     |
•
int
•
float
•
complex
39

Variables of numeric types are created when you assign a value to them, so in
| normal coding | you    | don’t   | need  | to bother. |        |     |
| ------------- | ------ | ------- | ----- | ---------- | ------ | --- |
| Example       | 4.2.3. | Numeric | Types | in         | Python |     |
| x = 1         | #      | int     |       |            |        |     |
1
| 2 y = 2.8 | #    | float   |     |              |       |           |
| --------- | ---- | ------- | --- | ------------ | ----- | --------- |
| 3 z = 3 + | 2j # | complex |     |              |       |           |
|           |      | Listing |     | 4.5: Numeric | Types | in Python |
This means you just assign values to a variable without worrying about what
| kind of data | type | it is. |     |     |     |     |
| ------------ | ---- | ------ | --- | --- | --- | --- |
print(type(x))
1
print(type(y))
2
print(type(z))
3
|     |     | Listing | 4.6: | Check | Data Types | in Python |
| --- | --- | ------- | ---- | ----- | ---------- | --------- |
If you use the Spyder Editor, you can see the data types that a variable has
| using the | Variable | Explorer |     | (Figure       | 4.2):  |           |
| --------- | -------- | -------- | --- | ------------- | ------ | --------- |
|           |          | Figure   |     | 4.2: Variable | Editor | in Spyder |
[End of Example]
| 4.2.2 | Strings |     |     |     |     |     |
| ----- | ------- | --- | --- | --- | --- | --- |
Strings in Python are surrounded by either single quotation marks, or double
| quotation | marks. | ’Hello’ | is the | same | as ”Hello”. |     |
| --------- | ------ | ------- | ------ | ---- | ----------- | --- |
Stringscanbeoutputtoscreenusingtheprintfunction. Forexample: print(”Hello”).
| Example      | 4.2.4.       | Using | Strings  | in Python |            |     |
| ------------ | ------------ | ----- | -------- | --------- | ---------- | --- |
| Below we     | see examples |       | of using | strings   | in Python: |     |
| 1 a = ”Hello | World!”      |       |          |           |            |     |
2
3 print(a)
4
print(a[1])
5
print(a[2:5])
6
print(len(a))
7
print(a.lower())
8
40

9 print(a.upper())
| 10 print(a.replace(”H”, |     |     | ”J”))   |      |         |           |     |
| ----------------------- | --- | --- | ------- | ---- | ------- | --------- | --- |
| 11 print(a.split(”      |     | ”)) |         |      |         |           |     |
|                         |     |     | Listing | 4.7: | Strings | in Python |     |
Asyouseeintheexample,therearemanybuilt-infunctionsformmanipulating
| strings in | Python. | The | Example |     | shows | only a few of them. |     |
| ---------- | ------- | --- | ------- | --- | ----- | ------------------- | --- |
Strings in Python are arrays of bytes, and we can use index to get a specific
| character | within | the | string | as shown | in  | the example code. |     |
| --------- | ------ | --- | ------ | -------- | --- | ----------------- | --- |
[End of Example]
| 4.2.3      | String | Input       |       |         |        |            |     |
| ---------- | ------ | ----------- | ----- | ------- | ------ | ---------- | --- |
| Python     | allows | for command |       | line    | input. |            |     |
| That means | we     | are able    | to    | ask the | user   | for input. |     |
| Example    | 4.2.5. | String      | Input | in      | Python |            |     |
The following example asks for the user’s name, then, by using the input()
| method,      | the program |      | prints  | the name | to  | the screen: |     |
| ------------ | ----------- | ---- | ------- | -------- | --- | ----------- | --- |
| print(”Enter |             | your | name:”) |          |     |             |     |
1
x = input()
2
| print(”Hello |     | , ” + | x)  |     |     |     |     |
| ------------ | --- | ----- | --- | --- | --- | --- | --- |
3
|     |     |     |     | Listing | 4.8: | String Input |     |
| --- | --- | --- | --- | ------- | ---- | ------------ | --- |
[End of Example]
| 4.3 | Built-in |     | Functions |     |     |     |     |
| --- | -------- | --- | --------- | --- | --- | --- | --- |
Python consists of lots of built-in functions. Some examples are the print func-
tionthatwealreadyhaveused(perhapswithoutnoticingitisactuallyaBuilt-in
function).
Python also consists of different Modules, Libraries or Packages. These Mod-
ules, Libraries or Packages consists of lots of predefined functions for different
topics or areas, such as mathematics, plotting, handling database systems, etc.
| See Section | 4.4     | for more | information |       | and       | details regarding | this.         |
| ----------- | ------- | -------- | ----------- | ----- | --------- | ----------------- | ------------- |
| In another  | chapter | we       | will        | learn | to create | our own functions | from scratch. |
41

| 4.4 | Python | Standard |     | Library |     |     |
| --- | ------ | -------- | --- | ------- | --- | --- |
Python allows you to split your program into modules that can be reused in
other Python programs. It comes with a large collection of standard modules
| that you | can use | as the | basis of | your programs. |     |     |
| -------- | ------- | ------ | -------- | -------------- | --- | --- |
ThePython Standard Library consistsofdifferentmodulesforhandlingfile
I/O,basicmathematics,etc. Youdon’tneedtoinstalltheseseparately,butyou
need to important them when you want to use some of these modules or some
| of the functions |     | within | these modules. |     |     |     |
| ---------------- | --- | ------ | -------------- | --- | --- | --- |
The math module has all the basic math functions you need, such as: Trigono-
metric functions: sin(x), cos(x), etc. Logarithmic functions: log(), log10(), etc.
| Constants | like   | pi, e, inf, | nan,     | etc.   |     |     |
| --------- | ------ | ----------- | -------- | ------ | --- | --- |
| Example   | 4.4.1. | Using       | the math | module |     |     |
We create some basic examples how to use a Library, a Package or a Module:
| If we need  | only   | the sin() | function, | we  | can do | like this: |
| ----------- | ------ | --------- | --------- | --- | ------ | ---------- |
| 1 from math | import | sin       |           |     |        |            |
2
3 x = 3.14
y = sin(x)
4
5
print(y)
6
| If we need  | a few  | functions, | we    | can do | like this: |     |
| ----------- | ------ | ---------- | ----- | ------ | ---------- | --- |
| 1 from math | import | sin        | , cos |        |            |     |
2
3 x = 3.14
4 y = sin(x)
print(y)
5
6
y = cos(x)
7
print(y)
8
| If we need | many | functions, | we  | can do | like this: |     |
| ---------- | ---- | ---------- | --- | ------ | ---------- | --- |
∗
| 1 from math | import |     |     |     |     |     |
| ----------- | ------ | --- | --- | --- | --- | --- |
2
x = 3.14
3
y = sin(x)
4
print(y)
5
6
y = cos(x)
7
8 print(y)
| We can   | also use | this alternative: |     |     |     |     |
| -------- | -------- | ----------------- | --- | --- | --- | --- |
| 1 import | math     |                   |     |     |     |     |
2
x = 3.14
3
y = math.sin(x)
4
5
print(y)
6
42

| We can   | also write | it    | like this: |     |     |     |     |
| -------- | ---------- | ----- | ---------- | --- | --- | --- | --- |
| 1 import | math       | as mt |            |     |     |     |     |
2
3 x = 3.14
4 y = mt.sin(x)
5
print(y)
6
|     |     |     |     |     |     |     | [End of Example] |
| --- | --- | --- | --- | --- | --- | --- | ---------------- |
There are advantages and disadvantages with the different approaches. In your
program you may need to use functions from many different modules or pack-
ages. If you import the whole module instead of just the function(s) you need
| you use | more of | the | computer | memory. |     |     |     |
| ------- | ------- | --- | -------- | ------- | --- | --- | --- |
Very often we also need to import and use multiple libraries where the different
| libraries | have some | functions |     | with the same | name but | different | use. |
| --------- | --------- | --------- | --- | ------------- | -------- | --------- | ---- |
OtherusefulmodulesinthePython Standard Libraryarestatistics(where
| you have | functions | like | mean(), | stdev(), | etc.) |     |     |
| -------- | --------- | ---- | ------- | -------- | ----- | --- | --- |
For more information about the functions in the Python Standard Library,
see:
https://docs.python.org/3/library/index.html
| 4.5 | Using | Python |     | Libraries, | Packages |     | and Mod- |
| --- | ----- | ------ | --- | ---------- | -------- | --- | -------- |
ules
Rather than having all of its functionality built into its core, Python was de-
signedtobehighlyextensible. Thisapproachhasadvantagesanddisadvantages.
A disadvantage is that you need to install these packages separately and then
| later import   | these | modules  |      | in your code. |     |     |     |
| -------------- | ----- | -------- | ---- | ------------- | --- | --- | --- |
| Some important |       | packages | are: |               |     |     |     |
•
| NumPy |        | - NumPy | is  | the fundamental | package | for | scientific computing |
| ----- | ------ | ------- | --- | --------------- | ------- | --- | -------------------- |
| with  | Python |         |     |                 |         |     |                      |
• SciPy - SciPy is a free and open-source Python library used for scientific
| computingandtechnicalcomputing. |     |     |     |     | SciPycontainsmodulesforoptimiza- |     |     |
| ------------------------------- | --- | --- | --- | --- | -------------------------------- | --- | --- |
tion,linearalgebra,integration,interpolation,specialfunctions,FFT,sig-
nalandimageprocessing,ODEsolversandothertaskscommoninscience
| and | engineering. |     |     |     |     |     |     |
| --- | ------------ | --- | --- | --- | --- | --- | --- |
•
| Matplotlib |     | - Matplotlib |     | is a Python | 2D plotting | library |     |
| ---------- | --- | ------------ | --- | ----------- | ----------- | ------- | --- |
43

| Lots of | other packages |     | exists, | depending | on  | what you | are going to solve. |
| ------- | -------------- | --- | ------- | --------- | --- | -------- | ------------------- |
These packages need to be downloaded and installed separately, or you choose
| to use, e.g., | a distribution |             | package |           | like Anaconda. |          |     |
| ------------- | -------------- | ----------- | ------- | --------- | -------------- | -------- | --- |
| Here you      | find           | an overview | of      | the NumPy |                | library: |     |
https://www.numpy.org
| Here you | find | an overview | of  | the SciPy | library: |     |     |
| -------- | ---- | ----------- | --- | --------- | -------- | --- | --- |
https://www.scipy.org
| Here you | find | an overview | of  | the Matplotlib |     | library: |     |
| -------- | ---- | ----------- | --- | -------------- | --- | -------- | --- |
https://matplotlib.org
You will learn the basics features in all these libraries. We will use all of the in
| different       | examples | and    | exercises | throughout |          | this textbook. |     |
| --------------- | -------- | ------ | --------- | ---------- | -------- | -------------- | --- |
| Example         | 4.5.1.   | Using  | libraries |            |          |                |     |
| In this example |          | we use | the NumPy |            | library: |                |     |
| 1 import        | numpy    | as np  |           |            |          |                |     |
2
3 x = 3
4
y = np.sin(x)
5
6
print(y)
7
In this example we use both the math module in the Python Standard Library
| and the  | NumPy   | library: |     |     |     |     |     |
| -------- | ------- | -------- | --- | --- | --- | --- | --- |
| 1 import | math as | mt       |     |     |     |     |     |
| import   | numpy   | as np    |     |     |     |     |     |
2
3
x = 3
4
5
y = mt.sin(x)
6
7
8 print(y)
9
10
11 y = np.sin(x)
12
print(y)
13
Note! As seen in this example we use a function called sin() which exists both
in the math module in the Python Standard Library and the NumPy library.
In this case they give the same results. In this case the following code is not
recommended:
∗
| 1 from math | import |     |     |     |     |     |     |
| ----------- | ------ | --- | --- | --- | --- | --- | --- |
| from numpy  | import | ∗   |     |     |     |     |     |
2
3
x = 3
4
5
44

6 y = sin(x)
7
8 print(y)
9
10
y = sin(x)
11
12
print(y)
13
In this case it works, but assume you have 2 different functions with the same
| name that | have different | meaning |     | in 2 different | libraries. |
| --------- | -------------- | ------- | --- | -------------- | ---------- |
[End of Example]
| 4.5.1 | Python Packages |     |     |     |     |
| ----- | --------------- | --- | --- | --- | --- |
InadditiontothePythonStandardLibrary,thereisagrowingcollectionofsev-
eral thousand components (from individual programs and modules to packages
and entire application development frameworks), available from the Python
| Package        | Index. |         |     |     |     |
| -------------- | ------ | ------- | --- | --- | --- |
| Python Package | Index  | (PYPI): |     |     |     |
https://pypi.org
| Here you | can download | and | install | individual | Python packages. |
| -------- | ------------ | --- | ------- | ---------- | ---------------- |
AneasyalternativeistheAnacondaDistribution,wheremanyofthemostused
| Python packages | are | included. |     |     |     |
| --------------- | --- | --------- | --- | --- | --- |
Anaconda:
https://www.anaconda.com/distribution/
| 4.6 | Plotting | in  | Python |     |     |
| --- | -------- | --- | ------ | --- | --- |
Typically you need to create some plots or charts. In order to make plots or
charts in Python you will need an external library. The most used library is
Matplotlib.
| Matplotlib | is a Python      | 2D  | plotting | library    |          |
| ---------- | ---------------- | --- | -------- | ---------- | -------- |
| Here you   | find an overview |     | of the   | Matplotlib | library: |
https://matplotlib.org
If you are familiar with MATLAB and basic plotting in MATLAB, using the
| Matplotlib | is very similar. |     |     |     |     |
| ---------- | ---------------- | --- | --- | --- | --- |
The main difference from MATLAB is that you need to import the library,
| either the     | whole library     | or  | one or | more functions. |            |
| -------------- | ----------------- | --- | ------ | --------------- | ---------- |
| For simplicity | we import         | the | whole  | library         | like this: |
| import         | matplotlib.pyplot |     | as plt |                 |            |
1
45

| Plotting | functions |     | that you | will use | a lot: |     |     |
| -------- | --------- | --- | -------- | -------- | ------ | --- | --- |
•
plot()
• title()
• xlabel()
• ylabel()
• axis()
• grid()
•
subplot()
•
legend()
•
show()
| Lets    | create | some basic | plotting | examples  | using | the Matplotlib | library: |
| ------- | ------ | ---------- | -------- | --------- | ----- | -------------- | -------- |
| Example |        | 4.6.1.     | Plotting | in Python |       |                |          |
In this example we have two arrays with data. We want to plot x vs. y. We
canassume xisatimeseries andyisthecorrespondingtemperatureindegrees
Celsius.
| 1 import | matplotlib.pyplot |     |     | as plt |     |     |     |
| -------- | ----------------- | --- | --- | ------ | --- | --- | --- |
2
| x = [1, | 2,  | 3, 4, | 5, 6, | 7, 8, | 9, 10] |     |     |
| ------- | --- | ----- | ----- | ----- | ------ | --- | --- |
3
4
| y = [5, | 2,4, | 4,  | 8, 7, | 4, 8, 10, | 9]  |     |     |
| ------- | ---- | --- | ----- | --------- | --- | --- | --- |
5
6
plt.plot(x,y)
7
| 8 plt.xlabel(’Time        |     |     | (s)’) |          |     |     |     |
| ------------------------- | --- | --- | ----- | -------- | --- | --- | --- |
| 9 plt.ylabel(’Temperature |     |     |       | (degC)’) |     |     |     |
10 plt.show()
| We get | the               | plot as | shown      | in Figure | 4.3. |     |     |
| ------ | ----------------- | ------- | ---------- | --------- | ---- | --- | --- |
| We can | also              | write   | like this: |           |      |     |     |
| from   | matplotlib.pyplot |         |            | import    | ∗    |     |     |
1
2
| 3 x = [1, | 2,   | 3, 4, | 5, 6, | 7, 8,     | 9, 10] |     |     |
| --------- | ---- | ----- | ----- | --------- | ------ | --- | --- |
| 4 y = [5, | 2,4, | 4,    | 8, 7, | 4, 8, 10, | 9]     |     |     |
5
6 plot(x,y)
| xlabel(’Time |     | (s)’) |     |     |     |     |     |
| ------------ | --- | ----- | --- | --- | --- | --- | --- |
7
| ylabel(’Temperature |     |     | (degC)’) |     |     |     |     |
| ------------------- | --- | --- | -------- | --- | --- | --- | --- |
8
show()
9
This makes the code simpler to read. one problem with this approach appears
assuming we import and use multiple libraries and the different libraries have
| some | functions | with | the same | name | but different | use. |     |
| ---- | --------- | ---- | -------- | ---- | ------------- | ---- | --- |
46

|     |     | Figure | 4.3: Plotting |     | in Python |     |
| --- | --- | ------ | ------------- | --- | --------- | --- |
[End of Example]
| We have | used 4 basic | plotting | function | in the | Matplotlib | library: |
| ------- | ------------ | -------- | -------- | ------ | ---------- | -------- |
• plot()
• xlabel()
• ylabel()
• show()
| Example      | 4.6.2. Plotting |     | a Sine Curve |     |     |     |
| ------------ | --------------- | --- | ------------ | --- | --- | --- |
| import numpy | as np           |     |              |     |     |     |
1
| import matplotlib.pyplot |     |     | as plt |     |     |     |
| ------------------------ | --- | --- | ------ | --- | --- | --- |
2
3
| x = [0, | 1, 2, 3, | 4, 5, | 6, 7] |     |     |     |
| ------- | -------- | ----- | ----- | --- | --- | --- |
4
5
6 y = np.sin(x)
7
| 8 plt.plot(x, | y)  |     |     |     |     |     |
| ------------- | --- | --- | --- | --- | --- | --- |
plt.xlabel(’x’)
9
plt.ylabel(’y’)
10
plt.show()
11
| This gives | the following | plot | (see Figure | 4.4): |     |     |
| ---------- | ------------- | ---- | ----------- | ----- | --- | --- |
| A better   | solution will | then | be:         |       |     |     |
47

|        | Figure            | 4.4: Plotting | a Sine function | in Python |
| ------ | ----------------- | ------------- | --------------- | --------- |
| import | matplotlib.pyplot | as plt        |                 |           |
1
| import | numpy as np |     |     |     |
| ------ | ----------- | --- | --- | --- |
2
3
| 4 xstart | = 0 |     |     |     |
| -------- | --- | --- | --- | --- |
2∗np.pi
5 xstop =
| 6 increment | = 0.1 |     |     |     |
| ----------- | ----- | --- | --- | --- |
7
| x = np.arange(xstart |     | ,xstop,increment) |     |     |
| -------------------- | --- | ----------------- | --- | --- |
8
9
y = np.sin(x)
10
11
| 12 plt.plot(x, | y)  |     |     |     |
| -------------- | --- | --- | --- | --- |
13 plt.xlabel(’x’)
14 plt.ylabel(’y’)
15 plt.show()
| This gives  | the following | plot (see Figure   | 4.5):     |     |
| ----------- | ------------- | ------------------ | --------- | --- |
| If you want | grids you     | can use the grid() | function. |     |
[End of Example]
| 4.6.1 | Subplots |     |     |     |
| ----- | -------- | --- | --- | --- |
Thesubplotcommandenablesyoutodisplaymultipleplotsinthesamewindow.
Typing ”subplot(m,n,p)” partitions the figure window into an m-by-n matrix
of small subplots and selects the subplot for the current plot. The plots are
numbered along the first row of the figure window, then the second row, and so
| on. See | Figure 4.6.     |          |     |     |
| ------- | --------------- | -------- | --- | --- |
| Example | 4.6.3. Creating | Subplots |     |     |
48

| Figure                   | 4.5: Plotting a | Sine function | in Python - Better       | Implementation |
| ------------------------ | --------------- | ------------- | ------------------------ | -------------- |
| We will create           | and plot sin()  | and cos()     | in 2 different subplots. |                |
| import matplotlib.pyplot |                 | as plt        |                          |                |
1
| import numpy | as np |     |     |     |
| ------------ | ----- | --- | --- | --- |
2
3
| xstart = | 0   |     |     |     |
| -------- | --- | --- | --- | --- |
4
| xstop = 2∗np.pi |     |     |     |     |
| --------------- | --- | --- | --- | --- |
5
| 6 increment | = 0.1 |     |     |     |
| ----------- | ----- | --- | --- | --- |
7
| 8 x = np.arange(xstart | ,xstop,increment) |     |     |     |
| ---------------------- | ----------------- | --- | --- | --- |
9
y = np.sin(x)
10
11
z = np.cos(x)
12
13
14
15 plt.subplot(2,1,1)
| 16 plt.plot(x,     | y, ’g’) |     |     |     |
| ------------------ | ------- | --- | --- | --- |
| 17 plt. title(’sin | ’)      |     |     |     |
18 plt.xlabel(’x’)
19 plt.ylabel(’sin(x)’)
plt.grid()
20
plt.show()
21
22
23
24 plt.subplot(2,1,2)
| 25 plt.plot(x, | z, ’r’) |     |     |     |
| -------------- | ------- | --- | --- | --- |
26 plt. title(’cos’)
27 plt.xlabel(’x’)
28 plt.ylabel(’cos(x)’)
plt.grid()
29
plt.show()
30
[End of Example]
49

|       | Figure    | 4.6: Creating Subplots | in Python |     |
| ----- | --------- | ---------------------- | --------- | --- |
| 4.6.2 | Exercises |                        |           |     |
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
| Exercise   | 4.6.1. Create        | sin(x) and cos(x)     | in 2 different plots |       |
| ---------- | -------------------- | --------------------- | -------------------- | ----- |
| Create     | sin(x) and cos(x)    | in 2 different plots. |                      |       |
| You should | use all the Plotting | functions             | listed below in your | code: |
• plot()
• title()
• xlabel()
• ylabel()
• axis()
• grid()
•
legend()
•
show()
[End of Exercise]
50

Part II
Python Programming
51

| Chapter | 5           |     |     |     |
| ------- | ----------- | --- | --- | --- |
| Python  | Programming |     |     |     |
WehavebeenthroughthebasicsinPython, suchasvariables, usingsomebasic
| built-in functions, | basic | plotting, etc. |     |     |
| ------------------- | ----- | -------------- | --- | --- |
You may come far only using these thins, but to create real applications, you
| need to know | about and | use features like: |     |     |
| ------------ | --------- | ------------------ | --- | --- |
| • If ...     | Else      |                    |     |     |
| • For        | Loops     |                    |     |     |
| • While      | Loops     |                    |     |     |
| • Arrays     | ...       |                    |     |     |
If you are familiar with one or more other programming language, these fea-
tures should be familiar and known to you. All programming languages have
these features built-in, but the syntax is slightly different from one language to
another.
| 5.1 If            | ... Else     |                       |                 |            |
| ----------------- | ------------ | --------------------- | --------------- | ---------- |
| An ”if statement” | is written   | by using              | the if keyword. |            |
| Here are some     | Examples     | how you use           | a If sentences  | in Python: |
| Example           | 5.1.1. Using | If ... Else in Python |                 |            |
Using If:
1 a = 5
b = 8
2
3
| if a > b: |     |     |     |     |
| --------- | --- | --- | --- | --- |
4
| print(”a | is greater | than b”) |     |     |
| -------- | ---------- | -------- | --- | --- |
5
6
| 7 if b > a: |            |          |     |     |
| ----------- | ---------- | -------- | --- | --- |
| 8 print(”b  | is greater | than a”) |     |     |
9
| 10 if a == b: |     |     |     |     |
| ------------- | --- | --- | --- | --- |
52

| 11 print(”a   | is equal   | to b”)       |     |     |
| ------------- | ---------- | ------------ | --- | --- |
|               |            | Listing 5.1: | If  |     |
| Try to change | the values | for a and b. |     |     |
| Using If -    | Else:      |              |     |     |
1 a = 5
2 b = 8
3
| 4 if a > b: |            |          |     |     |
| ----------- | ---------- | -------- | --- | --- |
| 5 print(”a  | is greater | than b”) |     |     |
else:
6
| print(”b | is greater | than a or a | and b are equal”) |     |
| -------- | ---------- | ----------- | ----------------- | --- |
7
|     |     | Listing 5.2: | If - Else |     |
| --- | --- | ------------ | --------- | --- |
Using Elif:
1 a = 5
2 b = 8
3
| if a > b: |     |     |     |     |
| --------- | --- | --- | --- | --- |
4
| print(”a | is greater | than b”) |     |     |
| -------- | ---------- | -------- | --- | --- |
5
| elif b > | a:  |     |     |     |
| -------- | --- | --- | --- | --- |
6
| print(”b | is greater | than a”) |     |     |
| -------- | ---------- | -------- | --- | --- |
7
| 8 elif a == | b:       |              |      |     |
| ----------- | -------- | ------------ | ---- | --- |
| 9 print(”a  | is equal | to b”)       |      |     |
|             |          | Listing 5.3: | Elif |     |
Note! Python uses ”elif” not ”elseif” like many other programming languages
do.
[End of Example]
| 5.2 Arrays |     |     |     |     |
| ---------- | --- | --- | --- | --- |
An array is a special variable, which can hold more than one value at a time.
| Here are some | Examples      | how you can create | and use Arrays | in Python: |
| ------------- | ------------- | ------------------ | -------------- | ---------- |
| Example       | 5.2.1. Arrays | in Python          |                |            |
| data = [1.6,  | 3.4, 5.5,     | 9.4]               |                |            |
1
2
3 N = len(data)
4
5 print(N)
6
print(data[2])
7
8
| data[2] = | 7.3 |     |     |     |
| --------- | --- | --- | --- | --- |
9
10
print(data[2])
11
53

12
13
| 14 for x in | data: |     |     |     |     |     |     |
| ----------- | ----- | --- | --- | --- | --- | --- | --- |
15 print(x)
16
17
data.append(11.4)
18
19
20
21 N = len(data)
22
23 print(N)
24
25
| for x in | data: |     |     |     |     |     |     |
| -------- | ----- | --- | --- | --- | --- | --- | --- |
26
print(x)
27
|            |             | Listing   |          | 5.4: Using | Arrays | in  | Python |
| ---------- | ----------- | --------- | -------- | ---------- | ------ | --- | ------ |
| You define | an array    | like      | this:    |            |        |     |        |
| 1 data =   | [1.6, 3.4,  | 5.5,      | 9.4]     |            |        |     |        |
| You can    | also use    | text like | this:    |            |        |     |        |
| 1 carlist  | = [”Volvo”, |           | ”Tesla”, | ”Ford”]    |        |     |        |
| You can    | use Arrays  | in        | Loops    | like this: |        |     |        |
| for x in   | data:       |           |          |            |        |     |        |
1
2 print(x)
| You can | return the | number | of  | elements | in the | array | like this: |
| ------- | ---------- | ------ | --- | -------- | ------ | ----- | ---------- |
1 N = len(data)
| You can | get a specific |     | value inside | the | array | like this: |     |
| ------- | -------------- | --- | ------------ | --- | ----- | ---------- | --- |
| index = | 2              |     |              |     |       |            |     |
1
2 x = cars[index]
| You can | use the append() |     | method | to  | add an | element | to an array: |
| ------- | ---------------- | --- | ------ | --- | ------ | ------- | ------------ |
data.append(11.4)
1
[End of Example]
You have many built in methods you can use in combination with arrays, like
| sort(), clear(), | copy(), |           | count(), | insert(),      | remove(), |     | etc. |
| ---------------- | ------- | --------- | -------- | -------------- | --------- | --- | ---- |
| You should       | look    | into test | all      | these methods. |           |     |      |
54

5.3 For Loops
A For loop is used for iterating over a sequence. I guess all your programs will
use one or more For loops. So if you have not used For loops before, make sure
to learn it now.
Below you see a basic example how you can use a For loop in Python:
1 for i in range(1, 10):
2 print(i)
The For loop is probably one of the most useful feature in Python (or in any
kind of programming language). Below you will see different examples how you
can use a For loop in Python.
Example 5.3.1. Using For Loops in Python
1 data = [1.6, 3.4, 5.5, 9.4]
2
3 for x in data:
4 print(x)
5
6
7 carlist = [”Volvo”, ”Tesla”, ”Ford”]
8
9 for car in carlist:
10 print(car)
Listing 5.5: Using For Loops in Python
The range() function is handy to use in For Loops:
1 N = 10
2
3 for x in range(N):
4 print(x)
Therange()functionreturnsasequenceofnumbers,startingfrom0bydefault,
and increments by 1 (by default), and ends at a specified number.
You can also use the range() function like this:
1 start = 4
2 stop= 12 #but not including
3
4 for x in range(start , stop):
5 print(x)
Finally, you can also use the range() function like this:
1 start = 4
2 stop = 12 #but not including
3 step = 2
4
5 for x in range(start , stop, step):
6 print(x)
55

You should try all these examples in order to learn the basic structure of a For
loop.
[End of Example]
| Example       | 5.3.2. | Using    | For | Loops | for      | Summation | of Data             |      |
| ------------- | ------ | -------- | --- | ----- | -------- | --------- | ------------------- | ---- |
| You typically |        | want to  | use | a For | loop for | find the  | sum of a given data | set. |
| data =        | [1,    | 5, 6, 3, | 12, | 3]    |          |           |                     |      |
1
2
sum = 0
3
4
| #Find | the Sum | of  | all the | numbers |     |     |     |     |
| ----- | ------- | --- | ------- | ------- | --- | --- | --- | --- |
5
| 6 for x | in data: |     |     |     |     |     |     |     |
| ------- | -------- | --- | --- | --- | --- | --- | --- | --- |
| 7 sum = | sum      | + x |     |     |     |     |     |     |
8
9 print(sum)
10
| #Find | the Mean | or  | Average | of  | all | the numbers |     |     |
| ----- | -------- | --- | ------- | --- | --- | ----------- | --- | --- |
11
12
N = len(data)
13
14
15 mean = sum/N
16
17 print(mean)
| This gives | the | following | results: |     |     |     |     |     |
| ---------- | --- | --------- | -------- | --- | --- | --- | --- | --- |
1 30
2 5.0
[End of Example]
Example5.3.3. ImplementingFibonacciNumbersUsingaForLoopinPython
Fibonacci numbers are used in the analysis of financial markets, in strategies
suchasFibonacciretracement,andareusedincomputeralgorithmssuchasthe
| Fibonacci | search | technique |     | and | the Fibonacci |     | heap data structure. |     |
| --------- | ------ | --------- | --- | --- | ------------- | --- | -------------------- | --- |
Theyalsoappearinbiologicalsettings, suchasbranchingintrees, arrangement
of leaves on a stem, the fruitlets of a pineapple, the flowering of artichoke, an
| uncurling | fern | and the | arrangement |     | of  | a pine cone. |     |     |
| --------- | ---- | ------- | ----------- | --- | --- | ------------ | --- | --- |
In mathematics, Fibonacci numbers are the numbers in the following sequence:
| 0, 1, 1, | 2 ,3, 5, | 8, 13, | 21, 34, | 55, | 89, 144, | ... |     |     |
| -------- | -------- | ------ | ------- | --- | -------- | --- | --- | --- |
Bydefinition,thefirsttwoFibonaccinumbersare0and1,andeachsubsequent
| number | is the | sum of | the previous |     | two. |     |     |     |
| ------ | ------ | ------ | ------------ | --- | ---- | --- | --- | --- |
Some sources omit the initial 0, instead beginning the sequence with two 1s.
56

Inmathematicalterms,thesequenceFnofFibonaccinumbersisdefinedbythe
| recurrence | relation     |     |     |         |     |       |
| ---------- | ------------ | --- | --- | ------- | --- | ----- |
|            |              |     | f   | =f +f   |     | (5.1) |
|            |              |     | n   | n−1 n−2 |     |       |
| with       | seed values: |     |     |         |     |       |
|            |              |     | f   | =0,f =1 |     |       |
|            |              |     |     | 0 1     |     |       |
We will write a Python script that calculates the N first Fibonacci numbers.
| The | Python Script | becomes | like this: |     |     |     |
| --- | ------------- | ------- | ---------- | --- | --- | --- |
N = 10
1
2
fib1 = 0
3
fib2 = 1
4
5
6 print(fib1)
7 print(fib2)
8
range(N−2):
9 for k in
| fib | next | = fib2 +fib1 |     |     |     |     |
| --- | ---- | ------------ | --- | --- | --- | --- |
10
| fib1 | = fib2 |     |     |     |     |     |
| ---- | ------ | --- | --- | --- | --- | --- |
11
| fib2 | = fib | next |     |     |     |     |
| ---- | ----- | ---- | --- | --- | --- | --- |
12
| print(fib |     | next) |     |     |     |     |
| --------- | --- | ----- | --- | --- | --- | --- |
13
|             | Listing   | 5.6: Fibonacci | Numbers | Using | a For Loop in Python |     |
| ----------- | --------- | -------------- | ------- | ----- | -------------------- | --- |
| Alternative | solution: |                |         |       |                      |     |
1 N = 10
2
| 3 fib = | [0, 1] |     |     |     |     |     |
| ------- | ------ | --- | --- | --- | --- | --- |
4
5
| for | k in range(N−2): |     |     |     |     |     |
| --- | ---------------- | --- | --- | --- | --- | --- |
6
| fib | next | = fib[k+1] | +fib[k] |     |     |     |
| --- | ---- | ---------- | ------- | --- | --- | --- |
7
| fib.append(fib |     | next) |     |     |     |     |
| -------------- | --- | ----- | --- | --- | --- | --- |
8
9
10 print(fib)
|         | Listing     | 5.7: Fibonacci | Numbers | Using a | For Loop in Python | - Alt2 |
| ------- | ----------- | -------------- | ------- | ------- | ------------------ | ------ |
| Another | alternative | solution:      |         |         |                    |        |
N = 10
1
2
fib = []
3
4
| for | k in range(N): |     |     |     |     |     |
| --- | -------------- | --- | --- | --- | --- | --- |
5
6 fib.append(0)
7
| 8 fib[0] | = 0 |     |     |     |     |     |
| -------- | --- | --- | --- | --- | --- | --- |
| 9 fib[1] | = 1 |     |     |     |     |     |
10
57

| 11 for | k in     | range(N−2): |         |     |     |     |
| ------ | -------- | ----------- | ------- | --- | --- | --- |
| 12     | fib[k+2] | = fib[k+1]  | +fib[k] |     |     |     |
13
14
print(fib)
15
|         | Listing     | 5.8: Fibonacci | Numbers | Using a | For Loop in Python | - Alt3 |
| ------- | ----------- | -------------- | ------- | ------- | ------------------ | ------ |
| Another | alternative | solution:      |         |         |                    |        |
| import  | numpy       | as np          |         |         |                    |        |
1
2
3
4 N = 10
5
| 6 fib | = np.zeros(N) |     |     |     |     |     |
| ----- | ------------- | --- | --- | --- | --- | --- |
7
| fib[0] | =   | 0   |     |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- |
8
| fib[1] | =   | 1   |     |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- |
9
10
| 11 for | k in     | range(N−2): |         |     |     |     |
| ------ | -------- | ----------- | ------- | --- | --- | --- |
| 12     | fib[k+2] | = fib[k+1]  | +fib[k] |     |     |     |
13
14
15 print(fib)
|     | Listing | 5.9: Fibonacci | Numbers | Using a | For Loop in Python | - Alt4 |
| --- | ------- | -------------- | ------- | ------- | ------------------ | ------ |
[End of Example]
| 5.3.1 |     | Nested For | Loops |     |     |     |
| ----- | --- | ---------- | ----- | --- | --- | --- |
In Python and other programming languages you can use one loop inside an-
other loop.
| Syntax | for           | nested For | loops in Python: |     |     |     |
| ------ | ------------- | ---------- | ---------------- | --- | --- | --- |
| 1 for  | iterating     | var in     | sequence:        |     |     |     |
| 2      | for iterating | var        | in sequence:     |     |     |     |
| 3      | statements(s) |            |                  |     |     |     |
4 statements(s)
| Simple | example: |               |      |     |     |     |
| ------ | -------- | ------------- | ---- | --- | --- | --- |
| 1 for  | i in     | range(1, 10): |      |     |     |     |
|        | for      | k in range(1, | 10): |     |     |     |
2
|     |     | print(i , k) |     |     |     |     |
| --- | --- | ------------ | --- | --- | --- | --- |
3
| Exercise |       | 5.3.1. Prime     | Numbers  |               |                |      |
| -------- | ----- | ---------------- | -------- | ------------- | -------------- | ---- |
| The      | first | 25 prime numbers | (all the | prime numbers | less than 100) | are: |
2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83,
89, 97
58

By definition a prime number has both 1 and itself as a divisor. If it has any
| other divisor, | it cannot | be prime. |     |     |
| -------------- | --------- | --------- | --- | --- |
Anaturalnumber(1, 2, 3, 4, 5, 6, etc.) iscalledaprimenumber(oraprime)if
it is greater than 1 and cannot be written as a product of two natural numbers
| that are both | smaller | than it. |     |     |
| ------------- | ------- | -------- | --- | --- |
Create a Python Script where you find all prime numbers between 1 and 200.
Tip! I guess this can be done in many different ways, but one way is to use 2
| nested For | Loops. |     |     |     |
| ---------- | ------ | --- | --- | --- |
[End of Exercise]
| 5.4 While | Loops |     |     |     |
| --------- | ----- | --- | --- | --- |
The while loop repeats a group of statements an indefinite number of times
| under control | of a logical | condition. |          |        |
| ------------- | ------------ | ---------- | -------- | ------ |
| Example       | 5.4.1. Using | While      | Loops in | Python |
1 m = 8
2
| 3 while m > | 2:  |     |     |     |
| ----------- | --- | --- | --- | --- |
| 4 print     | (m) |     |     |     |
−
| 5 m = m | 1       |       |             |                 |
| ------- | ------- | ----- | ----------- | --------------- |
|         | Listing | 5.10: | Using While | Loops in Python |
[End of Example]
5.5 Exercises
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
| Exercise  | 5.5.1. Plot | of Dynamic | System |     |
| --------- | ----------- | ---------- | ------ | --- |
| Given the | autonomous  | system:    |        |     |
x˙ =ax (5.2)
Where:
1
a=−
T
59

| where T      | is the time constant. |          |     |
| ------------ | --------------------- | -------- | --- |
| The solution | for the differential  | equation | is: |
x(t)=eatx (5.3)
0
| Set T=5 | and the initial | condition x(0)=1. |     |
| ------- | --------------- | ----------------- | --- |
Create a Script inPython (.py file) where you plot the solution x(t) in the time
interval:
0≤t≤25
| Add Grid, | and proper Title | and Axis Labels | to the plot. |
| --------- | ---------------- | --------------- | ------------ |
[End of Exercise]
60

| Chapter  | 6   |           |     |     |     |
| -------- | --- | --------- | --- | --- | --- |
| Creating |     | Functions |     | in  |     |
Python
6.1 Introduction
A function is a block of code which only runs when it is called. You can pass
data, known as parameters, into a function. A function can return data as a
result.
| Previously | we have been | using many of | the built-in | functions | in Python |
| ---------- | ------------ | ------------- | ------------ | --------- | --------- |
If you are familiar with one or more other programming language, creating and
using functions should be familiar and known to you. All programming lan-
guageshasthepossibilitytocreatefunctions,butthesyntaxisslightlydifferent
| from one language | to  | another. |     |     |     |
| ----------------- | --- | -------- | --- | --- | --- |
Some programming languages uses the term Method instead of a Function.
Functions and Methods behave in the same manner, but you could say that
MethodsarefunctionsthatbelongstoaClass. WewilllearnmoreaboutClasses
| in Chapter      | 7.        |                |                  |     |             |
| --------------- | --------- | -------------- | ---------------- | --- | ----------- |
| Scripts vs.     | Functions |                |                  |     |             |
| It is important | to know   | the difference | between a Script | and | a Function. |
Scripts:
| • A collection | of commands    | that you         | would execute | in  | the Editor |
| -------------- | -------------- | ---------------- | ------------- | --- | ---------- |
| • Used         | for automating | repetitive tasks |               |     |            |
Functions:
| • Operate | on information | (inputs) | fed into them | and return | outputs |
| --------- | -------------- | -------- | ------------- | ---------- | ------- |
• Have a separate workspace and internal variables that is only valid inside
| the function |     |     |     |     |     |
| ------------ | --- | --- | --- | --- | --- |
61

•
| Your  | own | user-defined |           | functions | work       | the same | way as  | the built-in | func- |
| ----- | --- | ------------ | --------- | --------- | ---------- | -------- | ------- | ------------ | ----- |
| tions | you | use all      | the time, | such      | as plot(), | rand(),  | mean(), | std(),       | etc.  |
Pythonhavelotsofbuilt-infunctions,butveryoftenweneedtocreateourown
| functions | (we could  | refer | to         | these functions |     | as user-defined |     | functions) |     |
| --------- | ---------- | ----- | ---------- | --------------- | --- | --------------- | --- | ---------- | --- |
| In Python | a function |       | is defined | using           | the | def keyword:    |     |            |     |
def FunctionName:
1
<statement−1>
2
.
3
4 .
5 <statement−N>
| 6 return  | ...    |        |          |         |     |         |     |     |     |
| --------- | ------ | ------ | -------- | ------- | --- | ------- | --- | --- | --- |
| Example   | 6.1.1. | Basic  | Function |         |     |         |     |     |     |
| Below you | see a  | simple | function | created | in  | Python: |     |     |     |
1 def add(x,y):
2
| 3 return | x + | y   |         |            |        |          |     |     |     |
| -------- | --- | --- | ------- | ---------- | ------ | -------- | --- | --- | --- |
|          |     |     | Listing | 6.1: Basic | Python | Function |     |     |     |
The function adds 2 numbers. The name of the function is add, and it returns
| the answer | using | the | return | statement. |     |     |     |     |     |
| ---------- | ----- | --- | ------ | ---------- | --- | --- | --- | --- | --- |
The statement return [expression] exits a function, optionally passing back an
expression to the caller. A return statement with no arguments is the same as
return None.
Note that you need to use a colon ”:” at the end of line where you define the
function.
| Note also | the indention |     | used. |     |     |     |     |     |     |
| --------- | ------------- | --- | ----- | --- | --- | --- | --- | --- | --- |
def add(x,y):
1
| Here you | see a | Python | script | where | we use | the function: |     |     |     |
| -------- | ----- | ------ | ------ | ----- | ------ | ------------- | --- | --- | --- |
1 def add(x,y):
2
| 3 return | x + | y   |     |     |     |     |     |     |     |
| -------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
4
5
x = 2
6
y = 5
7
8
9 z = add(x,y)
10
11 print(z)
|     | Listing |     | 6.2: Creating |     | and Using | a Python | Function |     |     |
| --- | ------- | --- | ------------- | --- | --------- | -------- | -------- | --- | --- |
62

|     |         |        |        |            |     |            |      | [End | of Example] |
| --- | ------- | ------ | ------ | ---------- | --- | ---------- | ---- | ---- | ----------- |
|     | Example | 6.1.2. | Create | a Function | in  | a separate | File |      |             |
WestartbycreatingaseparatePythonFile(myfunctions.py)forthefunction:
1 def average(x,y):
2
|     | return | (x  | + y)/2 |     |     |     |     |     |     |
| --- | ------ | --- | ------ | --- | --- | --- | --- | --- | --- |
3
|     |     |     | Listing | 6.3: | Function calculating |     | the | Average |     |
| --- | --- | --- | ------- | ---- | -------------------- | --- | --- | ------- | --- |
Next, we create a new Python File (e.g., testaverage.py) where we use the
|     | function         | we created: |        |     |         |     |     |     |     |
| --- | ---------------- | ----------- | ------ | --- | ------- | --- | --- | --- | --- |
|     | from myfunctions |             | import |     | average |     |     |     |     |
1
2
3 a = 2
4 b = 3
5
6 c = average(a,b)
7
print(c)
8
|     |           |               |        | Listing    | 6.4: Test of | Average   | function      |             |             |
| --- | --------- | ------------- | ------ | ---------- | ------------ | --------- | ------------- | ----------- | ----------- |
|     |           |               |        |            |              |           |               | [End        | of Example] |
|     | 6.2       | Functions     |        | with       | multiple     |           | return        | values      |             |
|     | Typically | we want       | to     | return     | more than    | one value | from          | a function. |             |
|     | Example   | 6.2.1.        | Create | a Function | Function     |           | with multiple | return      | values      |
|     | Create    | the following |        | example:   |              |           |               |             |             |
def stat(x):
1
2
| 3   | totalsum |     | = 0 |     |     |     |     |     |     |
| --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- |
4
| 5   | #Find    | the  | Sum        | of all | the numbers |     |     |     |     |
| --- | -------- | ---- | ---------- | ------ | ----------- | --- | --- | --- | --- |
| 6   | for      | x in | data:      |        |             |     |     |     |     |
|     | totalsum |      | = totalsum |        | + x         |     |     |     |     |
7
8
9
|     | #Find | the | Mean | or Average | of all | the | numbers |     |     |
| --- | ----- | --- | ---- | ---------- | ------ | --- | ------- | --- | --- |
10
11
| 12  | N = | len(data) |     |     |     |     |     |     |     |
| --- | --- | --------- | --- | --- | --- | --- | --- | --- | --- |
13
| 14  | mean | = totalsum/N |     |     |     |     |     |     |     |
| --- | ---- | ------------ | --- | --- | --- | --- | --- | --- | --- |
15
16
|     | return | totalsum, |     | mean |     |     |     |     |     |
| --- | ------ | --------- | --- | ---- | --- | --- | --- | --- | --- |
17
18
19
20
63

| 21 data = | [1, 5, | 6, 3, | 12, 3] |     |     |     |     |     |     |
| --------- | ------ | ----- | ------ | --- | --- | --- | --- | --- | --- |
22
23
| 24 totalsum, | mean | = stat(data) |     |     |     |     |     |     |     |
| ------------ | ---- | ------------ | --- | --- | --- | --- | --- | --- | --- |
25
| print(totalsum, |     | mean) |     |     |     |     |     |     |     |
| --------------- | --- | ----- | --- | --- | --- | --- | --- | --- | --- |
26
|               |     | Listing | 6.5: Function | with | multiple |     | return | values           |     |
| ------------- | --- | ------- | ------------- | ---- | -------- | --- | ------ | ---------------- | --- |
|               |     |         |               |      |          |     |        | [End of Example] |     |
| 6.3 Exercises |     |         |               |      |          |     |        |                  |     |
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
| Exercise | 6.3.1.   | Create      | Python | Function   |     |         |     |                   |     |
| -------- | -------- | ----------- | ------ | ---------- | --- | ------- | --- | ----------------- | --- |
| Create a | function | calcaverage |        | that finds | the | average | of  | two numbers.      |     |
|          |          |             |        |            |     |         |     | [End of Exercise] |     |
Exercise 6.3.2. Create Python functions for converting between radians and
degrees
Since most of the trigonometric functions require that the angle is expressed in
radians, we will create our own functions in order to convert between radians
and degrees.
It is quite easy to convert from radians to degrees or from degrees to radians.
| We have | that: |     |                          |     |     |     |     |     |       |
| ------- | ----- | --- | ------------------------ | --- | --- | --- | --- | --- | ----- |
|         |       |     | 2π[radians]=360[degrees] |     |     |     |     |     | (6.1) |
This gives:
180
|     |     |     | d[degrees]=r[radians]×( |     |     |     | )   |     | (6.2) |
| --- | --- | --- | ----------------------- | --- | --- | --- | --- | --- | ----- |
π
and
π
|     |     |     | r[radians]=d[degrees]×( |     |     |     | )   |     | (6.3) |
| --- | --- | --- | ----------------------- | --- | --- | --- | --- | --- | ----- |
180
Create two functions that convert from radians to degrees (r2d(x)) and from
| degrees to      | radians   | (d2r(x)) | respectively. |        |           |      |           |     |     |
| --------------- | --------- | -------- | ------------- | ------ | --------- | ---- | --------- | --- | --- |
| These functions |           | should   | be saved      | in one | Python    | file | .py.      |     |     |
| Test the        | functions | to make  | sure          | that   | they work | as   | expected. |     |     |
64

[End of Exercise]
Exercise 6.3.3. Create a Function that Implementing Fibonacci Numbers
Fibonacci numbers are used in the analysis of financial markets, in strategies
suchasFibonacciretracement,andareusedincomputeralgorithmssuchasthe
| Fibonacci | search | technique |     | and the | Fibonacci | heap | data structure. |
| --------- | ------ | --------- | --- | ------- | --------- | ---- | --------------- |
Theyalsoappearinbiologicalsettings, suchasbranchingintrees, arrangement
of leaves on a stem, the fruitlets of a pineapple, the flowering of artichoke, an
| uncurling | fern | and the | arrangement |     | of a pine | cone. |     |
| --------- | ---- | ------- | ----------- | --- | --------- | ----- | --- |
In mathematics, Fibonacci numbers are the numbers in the following sequence:
| 0, 1, 1, 2 | ,3, 5, | 8, 13, | 21, 34, | 55, 89, | 144, ... |     |     |
| ---------- | ------ | ------ | ------- | ------- | -------- | --- | --- |
Bydefinition,thefirsttwoFibonaccinumbersare0and1,andeachsubsequent
| number | is the | sum of | the previous |     | two. |     |     |
| ------ | ------ | ------ | ------------ | --- | ---- | --- | --- |
Some sources omit the initial 0, instead beginning the sequence with two 1s.
Inmathematicalterms,thesequenceFnofFibonaccinumbersisdefinedbythe
| recurrence | relation |      |              |      |      |                   |         |
| ---------- | -------- | ---- | ------------ | ---- | ---- | ----------------- | ------- |
|            |          |      |              | f =f | +f   |                   | (6.4)   |
|            |          |      |              | n    | n−1  | n−2               |         |
| with seed  | values:  |      |              |      |      |                   |         |
|            |          |      |              | f    | =0,f | =1                |         |
|            |          |      |              |      | 0 1  |                   |         |
| Create a   | Function | that | Implementing |      | the  | N first Fibonacci | Numbers |
[End of Exercise]
| Exercise  | 6.3.4.   | Prime   | Numbers |          |       |         |                     |
| --------- | -------- | ------- | ------- | -------- | ----- | ------- | ------------------- |
| The first | 25 prime | numbers |         | (all the | prime | numbers | less than 100) are: |
2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83,
89, 97
By definition a prime number has both 1 and itself as a divisor. If it has any
| other divisor, | it  | cannot | be prime. |     |     |     |     |
| -------------- | --- | ------ | --------- | --- | --- | --- | --- |
Anaturalnumber(1, 2, 3, 4, 5, 6, etc.) iscalledaprimenumber(oraprime)if
it is greater than 1 and cannot be written as a product of two natural numbers
| that are | both smaller |     | than it. |     |     |     |     |
| -------- | ------------ | --- | -------- | --- | --- | --- | --- |
Tip! I guess this can be implemented in many different ways, but one way is to
| use 2 nested | For | Loops. |     |     |     |     |     |
| ------------ | --- | ------ | --- | --- | --- | --- | --- |
65

CreateaPythonfunctionwhereyoucheckifagivennumberisaprimenumber
or not.
| You can check | the function | in the Command | Window | like this: |
| ------------- | ------------ | -------------- | ------ | ---------- |
| number =      | 4            |                |        |            |
1
checkifprime(number)
2
| Then Python | respond with | True or False. |     |     |
| ----------- | ------------ | -------------- | --- | --- |
[End of Exercise]
66

| Chapter  |     | 7   |         |     |     |           |
| -------- | --- | --- | ------- | --- | --- | --------- |
| Creating |     |     | Classes |     |     | in Python |
7.1 Introduction
Pythonisanobjectorientedprogramming(OOP)language. Almosteverything
| in Python | is an | object, | with its | properties | and | methods. |
| --------- | ----- | ------- | -------- | ---------- | --- | -------- |
Thefoundationforallobjectorientedprogramming(OOP)languagesareClasses.
| To create | a class, | use | the keyword | class: |     |     |
| --------- | -------- | --- | ----------- | ------ | --- | --- |
class ClassName:
1
2 <statement−1>
3 .
4 .
5 .
<statement−N>
6
| Example | 7.1.1. | Simple   | Class    | Example |     |     |
| ------- | ------ | -------- | -------- | ------- | --- | --- |
| We will | create | a simple | Class in | Python. |     |     |
1 class Car:
| 2 model | =   | ”Volvo” |     |     |     |     |
| ------- | --- | ------- | --- | --- | --- | --- |
| 3 color | =   | ”Blue”  |     |     |     |     |
4
5
car = Car()
6
7
8
print(car.model)
9
10 print(car.color)
|             |      |       | Listing    | 7.1: Simple | Python | Class |
| ----------- | ---- | ----- | ---------- | ----------- | ------ | ----- |
| The results | will | be in | this case: |             |        |       |
Volvo
1
Blue
2
67

Thisexampledon’tillustratethegoodthingswithclassessowewillcreatesome
more examples.
[End of Example]
| Example     |     | 7.1.2.        | Python Class |       |     |     |
| ----------- | --- | ------------- | ------------ | ----- | --- | --- |
| Lets create |     | the following | Python       | Code: |     |     |
class Car:
1
| model |     | = ”” |     |     |     |     |
| ----- | --- | ---- | --- | --- | --- | --- |
2
| 3 color |     | = ”” |     |     |     |     |
| ------- | --- | ---- | --- | --- | --- | --- |
4
5 car = Car()
6
| 7 car.model |     | = ”Volvo” |     |     |     |     |
| ----------- | --- | --------- | --- | --- | --- | --- |
| car.color   |     | = ”Blue”  |     |     |     |     |
8
9
| print(car.color |     |     | + ” ” + | car.model) |     |     |
| --------------- | --- | --- | ------- | ---------- | --- | --- |
10
11
| car.model |     | = ”Ford” |     |     |     |     |
| --------- | --- | -------- | --- | --- | --- | --- |
12
| 13 car.color |     | = ”Green” |     |     |     |     |
| ------------ | --- | --------- | --- | --- | --- | --- |
14
| 15 print(car.color |     |           | + ” ” +   | car.model) |              |         |
| ------------------ | --- | --------- | --------- | ---------- | ------------ | ------- |
|                    |     |           | Listing   | 7.2:       | Python Class | example |
| You should         |     | try these | examples. |            |              |         |
[End of Example]
| 7.2 | The |     | init | () Function |     |     |
| --- | --- | --- | ---- | ----------- | --- | --- |
In Python all classes have a built-in function called init (), which is always
| executed | when   | the | class is  | being initiated. |               |              |
| -------- | ------ | --- | --------- | ---------------- | ------------- | ------------ |
| In many  | other  | OOP | languages | we               | call this the | Constructor. |
| Exercise | 7.2.1. |     | The init  | () Function      |               |              |
Wewillcreateasimpleexamplewhereweusethe init ()functiontoillustrate
the principle.
| We change |     | our previous | Car | example | like this: |     |
| --------- | --- | ------------ | --- | ------- | ---------- | --- |
class Car:
1
| 2 def | init        | (self | , model, | color): |     |     |
| ----- | ----------- | ----- | -------- | ------- | --- | --- |
| 3     | self .model | =     | model    |         |     |     |
| 4     | self .color | =     | color    |         |     |     |
5
| 6 car1 | = Car(”Ford”, |     | ”Green”) |     |     |     |
| ------ | ------------- | --- | -------- | --- | --- | --- |
7
print(car1.model)
8
print(car1.color)
9
10
11
68

| 12 car2 | = Car(”Volvo”, |     |     | ”Blue”) |     |     |
| ------- | -------------- | --- | --- | ------- | --- | --- |
13
14 print(car2.model)
15 print(car2.color)
|              |      | Listing   |       | 7.3: Python Class   | Constructor | Example |
| ------------ | ---- | --------- | ----- | ------------------- | ----------- | ------- |
| Lets extend  |      | the Class | by    | defining a Function | as well:    |         |
| 1 # Defining |      | the       | Class | Car                 |             |         |
| 2 class      | Car: |           |       |                     |             |         |
| 3 def        |      | init      | (self | , model, color):    |             |         |
| 4            | self | .model    | =     | model               |             |         |
|              | self | .color    | =     | color               |             |         |
5
6
| def | displayCar(self): |     |     |     |     |     |
| --- | ----------------- | --- | --- | --- | --- | --- |
7
|     | print(self |     | .model) |     |     |     |
| --- | ---------- | --- | ------- | --- | --- | --- |
8
|     | print(self |     | .color) |     |     |     |
| --- | ---------- | --- | ------- | --- | --- | --- |
9
10
11
| 12 # Lets | start | using | the | Class |     |     |
| --------- | ----- | ----- | --- | ----- | --- | --- |
13
| 14 car1 | = Car(”Tesla”, |     |     | ”Red”) |     |     |
| ------- | -------------- | --- | --- | ------ | --- | --- |
15
car1.displayCar()
16
17
18
| 19 car2 | = Car(”Ford”, |     | ”Green”) |     |     |     |
| ------- | ------------- | --- | -------- | --- | --- | --- |
20
21 print(car2.model)
22 print(car2.color)
23
24
| car3 | = Car(”Volvo”, |     |     | ”Blue”) |     |     |
| ---- | -------------- | --- | --- | ------- | --- | --- |
25
26
print(car3.model)
27
print(car3.color)
28
29
30 car3.color=”Black”
31
32 car3.displayCar()
|     |     |     | Listing | 7.4: Python | Class with | Function |
| --- | --- | --- | ------- | ----------- | ---------- | -------- |
As you see from the code we have now defined a Class ”Car” that has 2 Class
variables called ”model” and ”color”, and in addition we have defined a Func-
| tion (or | Method) |     | called | ”displayCar()”. |     |     |
| -------- | ------- | --- | ------ | --------------- | --- | --- |
Its normal to use the term ”Method” for Functions that are defined within a
Class.
You declare class methods like normal functions with the exception that the
| first argument |     | to  | each method | is self. |     |     |
| -------------- | --- | --- | ----------- | -------- | --- | --- |
To create instances of a class, you call the class using class name and pass in
| whatever | arguments |     | its | init () method | accepts. |     |
| -------- | --------- | --- | --- | -------------- | -------- | --- |
For example:
69

1 car1 = Car(”Tesla”, ”Red”)
Listing 7.5: Import Class
[End of Example]
Exercise 7.2.2. Create the Class in a separate Python file
We start by creating the Class and then we save the code in ”Car.py”:
1 # Defining the Class Car
2 class Car:
3 def init (self , model, color):
4 self .model = model
5 self .color = color
6
7 def displayCar(self):
8 print(self .model)
9 print(self .color)
Listing 7.6: Define Python Class in separate File
Then we create a Python Script (testCar.py) where we are using the Class:
1 # Importing the Car Class
2 from Car import Car
3
4 # Lets start using the Class
5
6 car1 = Car(”Tesla”, ”Red”)
7
8 car1.displayCar()
9
10
11 car2 = Car(”Ford”, ”Green”)
12
13 print(car2.model)
14 print(car2.color)
15
16
17 car3 = Car(”Volvo”, ”Blue”)
18
19 print(car3.model)
20 print(car3.color)
21
22 car3.color=”Black”
23
24 car3.displayCar()
Listing 7.7: Script that is using the Class
Notice the following line at the top:
1 from Car import Car
[language=Python]
[End of Example]
70

7.3 Exercises
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
| Exercise | 7.3.1. Create | Python Class |     |     |
| -------- | ------------- | ------------ | --- | --- |
Create a Python Class where you calculate the degrees in Fahrenheit based on
| the temperature | in Celsius     | and vice        | versa.        |       |
| --------------- | -------------- | --------------- | ------------- | ----- |
| The formula     | for converting | from Celsius    | to Fahrenheit | is:   |
|                 |                | T f =(T         | c ×9/5)+32    | (7.1) |
| The formula     | for converting | from Fahrenheit | to Celsius    | is:   |
|                 |                | T =(T           | −32)×(5/9)    | (7.2) |
c f
[End of Exercise]
71

Chapter 8
Creating Python Modules
Asyourprogramgetslonger,youmaywanttosplititintoseveralfilesforeasier
maintenance. Youmayalsowanttouseahandyfunctionthatyouhavewritten
in several programs without copying its definition into each program.
To support this, Python has a way to put definitions in a file and use them
in a script or in an interactive instance of the interpreter (the Python Console
window).
8.1 Python Modules
A module is a file containing Python definitions and statements. The file name
is the module name with the suffix .py appended.
Python allows you to split your program into modules that can be reused in
other Python programs. It comes with a large collection of standard modules
that you can use as the basis of your programs as we have seen examples of in
previous chapters. Not it is time to make your own modules from scratch.
Consider a module to be the same as a code library. A file containing a set of
functions you want to include in your application.
Previously you have been using different modules, libraries or packages created
bythePythonorganizationorbyothers. Hereyouwillcreateyourownmodules
from scratch.
Example 8.1.1. Create your first Python Module
We will create a Python module with 2 functions. The first function should
convert from Celsius to Fahrenheit and the other function should convert from
Fahrenheit to Celsius.
The formula for converting from Celsius to Fahrenheit is:
T =(T ×9/5)+32 (8.1)
f c
72

| The formula | for | converting | from Fahrenheit  | to Celsius is: |
| ----------- | --- | ---------- | ---------------- | -------------- |
|             |     |            | T =(T −32)×(5/9) | (8.2)          |
c f
First,wecreateaPythonmodulewiththefollowingfunctions(fahrenheit.py):
def c2f(Tc):
1
2
| 3 Tf     | = (Tc | ∗ 9/5) | + 32 |     |
| -------- | ----- | ------ | ---- | --- |
| 4 return | Tf    |        |      |     |
5
6
def f2c(Tf):
7
8
| Tc  | = (Tf | − 32)∗(5/9) |     |     |
| --- | ----- | ----------- | --- | --- |
9
| return | Tc  |     |     |     |
| ------ | --- | --- | --- | --- |
10
|     |     | Listing | 8.1: Fahrenheit | Functions |
| --- | --- | ------- | --------------- | --------- |
Then,wecreateaPythonscriptfortestingthefunctions(testfahrenheit.py):
| 1 from | fahrenheit | import | c2f , f2c |     |
| ------ | ---------- | ------ | --------- | --- |
2
3 Tc = 0
4
Tf = c2f(Tc)
5
6
| print(”Fahrenheit: |     | ”   | + str(Tf)) |     |
| ------------------ | --- | --- | ---------- | --- |
7
8
9
10 Tf = 32
11
12 Tc = f2c(Tf)
13
| print(”Celsius: |     | ” + | str(Tc)) |     |
| --------------- | --- | --- | -------- | --- |
14
|             |          | Listing | 8.2: Python Script | testing the functions |
| ----------- | -------- | ------- | ------------------ | --------------------- |
| The results | becomes: |         |                    |                       |
| Fahrenheit: | 32.0     |         |                    |                       |
1
| 2 Celsius: | 0.0       |     |     |     |
| ---------- | --------- | --- | --- | --- |
| 8.2        | Exercises |     |     |     |
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
Exercise 8.2.1. Create Python Module for converting between radians and
degrees
Since most of the trigonometric functions require that the angle is expressed in
radians, we will create our own functions in order to convert between radians
73

and degrees.
It is quite easy to convert from radians to degrees or from degrees to radians.
| We have that: |                          |     |     |       |
| ------------- | ------------------------ | --- | --- | ----- |
|               | 2π[radians]=360[degrees] |     |     | (8.3) |
This gives:
180
|     | d[degrees]=r[radians]×( |     | )   | (8.4) |
| --- | ----------------------- | --- | --- | ----- |
π
and
π
|     | r[radians]=d[degrees]×( |     | )   | (8.5) |
| --- | ----------------------- | --- | --- | ----- |
180
Create two functions that convert from radians to degrees (r2d(x)) and from
| degrees to radians | (d2r(x)) respectively. |               |           |     |
| ------------------ | ---------------------- | ------------- | --------- | --- |
| These functions    | should be saved        | in one Python | file .py. |     |
Test the functions to make sure that they work as expected. You can choose to
make a new .py file to test these functions or you can use the Console window.
[End of Exercise]
74

| Chapter |          | 9   |     |     |     |        |     |     |     |
| ------- | -------- | --- | --- | --- | --- | ------ | --- | --- | --- |
| File    | Handling |     |     |     | in  | Python |     |     |     |
9.1 Introduction
Python has several functions for creating, reading, updating, and deleting files.
| The key    | function | for working |         | with files  | in  | Python is   | the open() |       | function. |
| ---------- | -------- | ----------- | ------- | ----------- | --- | ----------- | ---------- | ----- | --------- |
| The open() | function | takes       | two     | parameters; |     | Filename,   | and        | Mode. |           |
| There are  | four     | different   | methods | (modes)     |     | for opening | a file:    |       |           |
•
| ”x” | - Create | - Creates |     | the specified |     | file, returns | an error | if  | the file exists |
| --- | -------- | --------- | --- | ------------- | --- | ------------- | -------- | --- | --------------- |
•
| ”w” | - Write | - Opens | a   | file for | writing, | creates | the file | if it does | not exist |
| --- | ------- | ------- | --- | -------- | -------- | ------- | -------- | ---------- | --------- |
•
| ”r” | - Read | - Default | value. | Opens | a   | file for reading, |     | error if | the file does |
| --- | ------ | --------- | ------ | ----- | --- | ----------------- | --- | -------- | ------------- |
| not | exist  |           |        |       |     |                   |     |          |               |
• ”a” - Append - Opens a file for appending, creates the file if it does not
exist
In addition you can specify if the file should be handled as binary or text mode
| • ”t” | - Text   | - Default | value. | Text       | mode    |     |     |     |     |
| ----- | -------- | --------- | ------ | ---------- | ------- | --- | --- | --- | --- |
| • ”b” | - Binary | - Binary  |        | mode (e.g. | images) |     |     |     |     |
| 9.2   | Write    | Data      | to     | a File     |         |     |     |     |     |
TocreateaNewfileinPython,usetheopen()method,withoneofthefollowing
parameters:
| • ”x” | - Create | - Creates |     | the specified |          | file, returns | an error | if         | the file exists |
| ----- | -------- | --------- | --- | ------------- | -------- | ------------- | -------- | ---------- | --------------- |
| • ”w” | - Write  | - Opens   | a   | file for      | writing, | creates       | the file | if it does | not exist       |
• ”a” - Append - Opens a file for appending, creates the file if it does not
exist
75

To write to an Existing file, you must add a parameter to the open() function:
| • ”w” - Write | - Opens | a file for writing, | creates | the file if it does | not exist |
| ------------- | ------- | ------------------- | ------- | ------------------- | --------- |
• ”a” - Append - Opens a file for appending, creates the file if it does not
exist
| Example 9.2.1.           | Write Data | to a File |     |     |     |
| ------------------------ | ---------- | --------- | --- | --- | --- |
| 1 f = open(”myfile.txt”, |            | ”x”)      |     |     |     |
2
| data = ”Hello | World” |     |     |     |     |
| ------------- | ------ | --- | --- | --- | --- |
3
4
f.write(data)
5
6
f.close()
7
|          | Listing | 9.1: Write  | Data to a | File |             |
| -------- | ------- | ----------- | --------- | ---- | ----------- |
|          |         |             |           | [End | of Example] |
| 9.3 Read | Data    | from a File |           |      |             |
To read to an existing file, you must add the following parameter to the open()
function:
• ”r” - Read - Default value. Opens a file for reading, error if the file does
| not exist                |           |             |     |     |     |
| ------------------------ | --------- | ----------- | --- | --- | --- |
| Example 9.3.1.           | Read Data | from a File |     |     |     |
| 1 f = open(”myfile.txt”, |           | ”r”)        |     |     |     |
2
3 data = f.read()
4
print(data)
5
6
f.close()
7
|             | Listing | 9.2: Read | Data from a | File |             |
| ----------- | ------- | --------- | ----------- | ---- | ----------- |
|             |         |           |             | [End | of Example] |
| 9.4 Logging | Data    | to File   |             |      |             |
Typically you want to write multiple data to the, e.g., assume you read some
temperaturedataatregularintervalsandthenyouwanttosavethetemperature
| values to a File. |         |              |     |     |     |
| ----------------- | ------- | ------------ | --- | --- | --- |
| Example 9.4.1.    | Logging | Data to File |     |     |     |
76

| 1 data = | [1.6, | 3.4, 5.5, | 9.4] |     |     |
| -------- | ----- | --------- | ---- | --- | --- |
2
| 3 f = open(”myfile.txt”, |     |     | ”x”) |     |     |
| ------------------------ | --- | --- | ---- | --- | --- |
4
| for value | in  | data: |     |     |     |
| --------- | --- | ----- | --- | --- | --- |
5
| record | =   | str(value) |     |     |     |
| ------ | --- | ---------- | --- | --- | --- |
6
f.write(record)
7
f.write(”\n”)
8
9
10 f.close()
|     |     |     | Listing | 9.3: Logging | Data to File |
| --- | --- | --- | ------- | ------------ | ------------ |
[End of Example]
| Example                | 9.4.2. | Read | Logged | Data from | File |
| ---------------------- | ------ | ---- | ------ | --------- | ---- |
| f = open(”myfile.txt”, |        |      | ”r”)   |           |      |
1
2
| for record | in  | f:  |     |     |     |
| ---------- | --- | --- | --- | --- | --- |
3
| 4 record | =   | record.replace(”\n”, |     | ””) |     |
| -------- | --- | -------------------- | --- | --- | --- |
5 print(record)
6
7 f.close()
|     |     | Listing | 9.4: | Read Logged | Data from File |
| --- | --- | ------- | ---- | ----------- | -------------- |
[End of Example]
| 9.5                                     | Web           | Resources |               |           |                     |
| --------------------------------------- | ------------- | --------- | ------------- | --------- | ------------------- |
| Below you                               | find          | different | useful        | resources | for File Handling.  |
| Python                                  | File Handling | -         | w3school:     |           |                     |
| https://www.w3schools.com/python/python |               |           |               |           | f ile h andling.asp |
| Reading                                 | and Writing   | Files     | - python.org: |           |                     |
https://docs.python.org/3/tutorial/inputoutput.htmlreading-and-writing-files
| 9.6 | Exercises |     |     |     |     |
| --- | --------- | --- | --- | --- | --- |
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
| Exercise | 9.6.1. | Data | Logging |     |     |
| -------- | ------ | ---- | ------- | --- | --- |
AssumeyouhavethefollowingdatayouwanttologtoaFileasshowninTable
9.1.
| Log these      | data | to a File. |        |            |                |
| -------------- | ---- | ---------- | ------ | ---------- | -------------- |
| Create another |      | Python     | Script | that reads | the same data. |
77

[End of Exercise]
Exercise 9.6.2. Data Logging 2
AssumeyoureaddatafromaTemperaturesensorevery10secondsforaperiod
of let say 5 minutes.
Log the data to a File.
You can use the Random Generator in Python. An example of how to use the
Random Generator is shown below:
1 import random
2 for x in range(10):
3 data = random.randint(1,31)
4 print(data)
Listing 9.5: Read Data from a File
Make sure to log both the time and the temperature value
Create another Python Script that reads the same data.
You should also plot the data you read from the File.
[End of Exercise]
78

Table 9.1: Logged Data
Time Value
1 22
2 25
3 28
... ...
79

| Chapter |              | 10  |     |          |     |          |        |     |
| ------- | ------------ | --- | --- | -------- | --- | -------- | ------ | --- |
| Error   | Handling     |     |     |          |     | in       | Python |     |
| 10.1    | Introduction |     |     | to Error |     | Handling |        |     |
So far error messages haven’t been discussed. You could say that we have 2
| kinds of        | errors: syntax | errors | and       | exceptions. |     |     |     |     |
| --------------- | -------------- | ------ | --------- | ----------- | --- | --- | --- | --- |
| 10.1.1          | Syntax         | Errors |           |             |     |     |     |     |
| Below we        | see an example |        | of syntax | errors:     |     |     |     |     |
| >>> print(Hello |                | World) |           |             |     |     |     |     |
1
| File | ”<ipython−input−1−10cb182148e3>”, |     |     |     |     | line | 1   |     |
| ---- | --------------------------------- | --- | --- | --- | --- | ---- | --- | --- |
2
| print(Hello |     | World) |     |     |     |     |     |     |
| ----------- | --- | ------ | --- | --- | --- | --- | --- | --- |
3
ˆ
4
| 5 SyntaxError: | invalid |     | syntax |     |     |     |     |     |
| -------------- | ------- | --- | ------ | --- | --- | --- | --- | --- |
In the example we have written print(Hello World) instead of print(”Hello
| World”) | and then   | the Python | Interpreter |     | gives | us  | an error | message. |
| ------- | ---------- | ---------- | ----------- | --- | ----- | --- | -------- | -------- |
| 10.1.2  | Exceptions |            |             |     |       |     |          |          |
Even if a statement or expression is syntactically correct, it may cause an error
when an attempt is made to execute it. Errors detected during execution are
called exceptions and are not unconditionally fatal: you will soon learn how to
handletheminPythonprograms. Mostexceptionsarenothandledbyprograms,
| however,    | and result | in error | messages |        | as shown | here: |     |     |
| ----------- | ---------- | -------- | -------- | ------ | -------- | ----- | --- | --- |
| 1 >>> 10    | ∗ (1/0)    |          |          |        |          |       |     |     |
| 2 Traceback | (most      | recent   | call     | last): |          |       |     |     |
3
”<ipython−input−2−0b280f36835c>”,
| 4 File |     |     |     |     |     | line | 1,  | in <module> |
| ------ | --- | --- | --- | --- | --- | ---- | --- | ----------- |
∗
| 5 10 | (1/0) |     |     |     |     |     |     |     |
| ---- | ----- | --- | --- | --- | --- | --- | --- | --- |
6
| ZeroDivisionError: |     | division |     | by zero |     |     |     |     |
| ------------------ | --- | -------- | --- | ------- | --- | --- | --- | --- |
7
or:
| >>> ’2’ | + 2 |     |     |     |     |     |     |     |
| ------- | --- | --- | --- | --- | --- | --- | --- | --- |
1
| Traceback | (most | recent | call | last): |     |     |     |     |
| --------- | ----- | ------ | ---- | ------ | --- | --- | --- | --- |
2
3
80

| 4   | File ”<ipython−input−3−d2b23a1db757>”, |     |     |     | line | 1, in <module> |
| --- | -------------------------------------- | --- | --- | --- | ---- | -------------- |
| 5   | ’2’                                    | + 2 |     |     |      |                |
6
| 7 TypeError: |             | must       | be str ,          | not int      |             |                    |
| ------------ | ----------- | ---------- | ----------------- | ------------ | ----------- | ------------------ |
| 10.2         |             | Exceptions |                   | Handling     |             |                    |
| It           | is possible | to         | write programs    | that handle  | selected    | exceptions.        |
| In           | Python      | we can     | use the following | built-in     | Exceptions  | Handling features: |
|              | • The       | try block  | lets you          | test a block | of code for | errors.            |
|              | • The       | except     | block lets        | you handle   | the error.  |                    |
• Thefinallyblockletsyouexecutecode,regardlessoftheresultofthetry-
|     | and | except | blocks. |     |     |     |
| --- | --- | ------ | ------- | --- | --- | --- |
Whenanerroroccurs,orexceptionaswecallit,Pythonwillnormallystopand
| generate |            | an error | message.       |       |                  |             |
| -------- | ---------- | -------- | -------------- | ----- | ---------------- | ----------- |
| These    | exceptions |          | can be handled | using | the try - except | statements. |
| Some     | basic      | example: |                |       |                  |             |
try:
1
|     | 10 ∗ | (1/0) |     |     |     |     |
| --- | ---- | ----- | --- | --- | --- | --- |
2
except:
3
|     | print(”The |     | calculation | failed”) |     |     |
| --- | ---------- | --- | ----------- | -------- | --- | --- |
4
or:
try:
1
print(x)
2
3 except:
| 4   | print(”x | is       | not defined”)        |     |     |     |
| --- | -------- | -------- | -------------------- | --- | --- | --- |
| You | can      | also use | multiple exceptions: |     |     |     |
1 try:
2 print(x)
| 3 except | NameError: |     |               |     |     |     |
| -------- | ---------- | --- | ------------- | --- | --- | --- |
| 4        | print(”x   | is  | not defined”) |     |     |     |
except:
5
|     | print(”Something |     | is wrong”) |     |     |     |
| --- | ---------------- | --- | ---------- | --- | --- | --- |
6
The finally block, if specified, will be executed regardless if the try block raises
| an  | error | or not. |     |     |     |     |
| --- | ----- | ------- | --- | --- | --- | --- |
Example:
81

1 x=2
2
3 try:
4 print(x)
except NameError:
5
| print(”x | is not defined”) |     |     |
| -------- | ---------------- | --- | --- |
6
except:
7
| print(”Something | is wrong”) |     |     |
| ---------------- | ---------- | --- | --- |
8
9 finally:
| 10 print(”The | Program | is finished”) |     |
| ------------- | ------- | ------------- | --- |
Ingeneralyoushouldusetry-except-finallywhenyoutrytoopenaFile,read
| or write to Files, | connect to | a Database, etc. |     |
| ------------------ | ---------- | ---------------- | --- |
Example:
try:
1
f = open(”myfile.txt”)
2
| 3 f.write(”Lorum | Ipsum”) |     |     |
| ---------------- | ------- | --- | --- |
4 except:
| 5 print(”Something | went | wrong when writing | to the file”) |
| ------------------ | ---- | ------------------ | ------------- |
6 finally:
7 f.close()
82

| Chapter   | 11  |     |        |
| --------- | --- | --- | ------ |
| Debugging |     | in  | Python |
Debugging is the process of finding and resolving defects or problems within
a computer program that prevent correct operation of computer software or a
system [14].
Debuggers are software tools which enable the programmer to monitor the ex-
ecution of a program, stop it, restart it, set breakpoints, and change values in
memory. The term debugger can also refer to the person who is doing the de-
bugging.
As a programmer, one of the first things that you need for serious program
| development | is a debugger. |     |     |
| ----------- | -------------- | --- | --- |
Python has a built-in debugger that can be used if you are coding Python with
a basic text editor and running your Python programs from the command line.
A better option is to use the Debugging features integrated in your Python Ed-
itor. Debugging is typically integrated with the Python Editor you are using.
| See the specific | chapter | for the different | Python Editors. |
| ---------------- | ------- | ----------------- | --------------- |
83

| Chapter    | 12  |     |       |        |
| ---------- | --- | --- | ----- | ------ |
| Installing |     | and | using | Python |
Packages
A package contains all the files you need for a module. Modules are Python
| code libraries | you can include | in your | project. |     |
| -------------- | --------------- | ------- | -------- | --- |
Since Python is open source you can find thousands of Python Packages that
| you can install | and use | in your Python | programs. |     |
| --------------- | ------- | -------------- | --------- | --- |
You can use a Python Distribution like Anaconda Distribution (or similar
Python Distributions) to download and install many common Python Pack-
| ages as mentioned | previously. |      |     |     |
| ----------------- | ----------- | ---- | --- | --- |
| 12.1              | What is     | PIP? |     |     |
PIP is a package manager for Python packages, or modules if you like. PIP is
| a tool for | installing Python | packages. |     |     |
| ---------- | ----------------- | --------- | --- | --- |
IfyoudonothavePIPinstalled,youcandownloadandinstallitfromthispage:
https://pypi.org/project/pip/
PIP is typically used from the Command Prompt (Windows) or Terminal win-
dow (macOS).
| Installing  | Python Packages: |     |     |     |
| ----------- | ---------------- | --- | --- | --- |
| pip install | packagename      |     |     |     |
1
| Uninstalling    | Python Packages: |     |     |     |
| --------------- | ---------------- | --- | --- | --- |
| 1 pip uninstall | packagename      |     |     |     |
Some Python Editors also have a graphical way of installing Python Packages,
| like, e.g., | Visual Studio. |     |     |     |
| ----------- | -------------- | --- | --- | --- |
84

Part III
| Python | Environments | and |
| ------ | ------------ | --- |
Distributions
85

| Chapter      | 13  |     |        |
| ------------ | --- | --- | ------ |
| Introduction |     | to  | Python |
| Environments |     |     | and    |
Distributions
| Python comes | with many | flavours and | version. |
| ------------ | --------- | ------------ | -------- |
Python is open source and everybody can bundle and distribute Python and
| different Python | Packages. |     |     |
| ---------------- | --------- | --- | --- |
A Python environment is a context in which you run Python code and includes
Python Packages.
Anenvironmentconsistsofaninterpreter,alibrary(typicallythePythonStan-
| dard Library), | and a set | of installed packages. |     |
| -------------- | --------- | ---------------------- | --- |
These components together determine which language constructs and syntax
are valid, what operating-system functionality you can access, and which pack-
| ages you can | use.     |                     |                   |
| ------------ | -------- | ------------------- | ----------------- |
| You can have | multiple | Python Environments | on your Computer. |
| Some of them | are:     |                     |                   |
•
| CPython | distribution | available from | python.org |
| ------- | ------------ | -------------- | ---------- |
•
Anaconda
•
| Enthought | Canopy |     |     |
| --------- | ------ | --- | --- |
•
WinPython
•
etc.
It is easy to start using Python by installing one of these Python Distributions.
86

| But you | can also install | the core Python | from: |     |
| ------- | ---------------- | --------------- | ----- | --- |
https://www.python.org
| Then install | the additional | Python Packages | you | need by using PIP. |
| ------------ | -------------- | --------------- | --- | ------------------ |
https://pypi.org/project/pip/
| 13.1 | Package | and Environment |     | Managers |
| ---- | ------- | --------------- | --- | -------- |
The two most popular tools for installing Python Packages and setting up
| Python environments |            | are:            |     |     |
| ------------------- | ---------- | --------------- | --- | --- |
| • PIP               | - a Python | Package Manager |     |     |
• Conda - a Package and Environment Manager (for Python and other lan-
guages)
| 13.1.1 | PIP |     |     |     |
| ------ | --- | --- | --- | --- |
Web:
https://pypi.org
PIP is typically used from the Command Prompt (Windows) or Terminal win-
dow (macOS).
| Installing    | Python Packages: |           |     |     |
| ------------- | ---------------- | --------- | --- | --- |
| 1 pip install | packagename      |           |     |     |
| Uninstalling  | Python           | Packages: |     |     |
| pip uninstall | packagename      |           |     |     |
1
| 13.1.2 | Conda |     |     |     |
| ------ | ----- | --- | --- | --- |
Conda is an open source package management system and environment man-
agementsystemthatrunsonWindows,macOSandLinux. Condainstalls,runs
| and updates | packages | and their dependencies. |     |     |
| ----------- | -------- | ----------------------- | --- | --- |
TheCondapackageandenvironmentmanagerisincludedinallversionsofAna-
conda.
CondawascreatedforPythonprograms,butitcanpackageanddistributesoft-
| ware for | any language. |     |     |     |
| -------- | ------------- | --- | --- | --- |
Condaallowsyoutotoalsocreateseparateenvironmentscontainingfiles,pack-
ages and their dependencies that will not interact with other environments.
87

Web:
https://conda.io/
| Conda is | part of or | integrated | with | the Anaconda | Python Distribution. |
| -------- | ---------- | ---------- | ---- | ------------ | -------------------- |
Web:
https://www.anaconda.com
| 13.2 | Python | Virtual |     | Environments |     |
| ---- | ------ | ------- | --- | ------------ | --- |
Python ”Virtual Environments” allow Python packages to be installed in an
isolated location for a particular application, rather than being installed glob-
ally.
| You can | have multiple | Python | Environments | on  | your computer. |
| ------- | ------------- | ------ | ------------ | --- | -------------- |
Python Virtual Environments have their own installation directories and they
| don’t share | libraries | with other | virtual | environments. |     |
| ----------- | --------- | ---------- | ------- | ------------- | --- |
Python”VirtualEnvironments”ishandywhenyouhavedifferentPythonappli-
cationsthatneedsdifferentversionsofPythonordifferentversionofthePython
| Packages | you are using. |     |     |     |     |
| -------- | -------------- | --- | --- | --- | --- |
88

| Chapter | 14  |     |     |     |
| ------- | --- | --- | --- | --- |
Anaconda
Anaconda is not an Editor, but a Python Distribution package. Spyder is in-
cludedinthePythonDistributionpackage. YoucanalsouseAnacondatoinstall
| other Editors   | or Python    | packages. |            |     |
| --------------- | ------------ | --------- | ---------- | --- |
| It is available | for Windows, | macOS     | and Linux. |     |
Web:
https://www.anaconda.com
Wikipedia:
| https://en.wikipedia.org/wiki/Anaconda |     |     | Python | istribution) |
| -------------------------------------- | --- | --- | ------ | ------------ |
( d
| 14.1 | Anaconda | Navigator |     |     |
| ---- | -------- | --------- | --- | --- |
Anaconda Navigator is a desktop graphical user interface (GUI) included in
Anaconda distribution that allows users to launch applications and manage
Python packages. The Anaconda Navigator can search for packages and install
| them on     | your computer,     | run the packages | and update | them. |
| ----------- | ------------------ | ---------------- | ---------- | ----- |
| Figure 14.1 | shows the Anaconda | Navigator.       |            |       |
| 14.2        | Anaconda           | Prompt           |            |       |
YoucanusetheAnacondaPromptifyouneedtoinstallextraPythonpackages,
etc.
Let say you want to install the Python Control Systems Library package. Just
| enter the   | following in the | Anaconda | Prompt: |     |
| ----------- | ---------------- | -------- | ------- | --- |
| pip install | control          |          |         |     |
89

|     | Figure | 14.1: Anaconda | Navigator |     |
| --- | ------ | -------------- | --------- | --- |
Python Package Index, or just pip, is a tool used to handle and install Python
packages.
For for information about pip and different packages you can install, see the
following:
https://pypi.org
Figure14.2showswhereyoucanfindtheAnacondaPrompt. Windows: Search
| for Anaconda | Prompt in | the Search field | in the start | menu. |
| ------------ | --------- | ---------------- | ------------ | ----- |
90

Figure 14.2: Anaconda Navigator
91

| Chapter   |     | 15     |     |
| --------- | --- | ------ | --- |
| Enthought |     | Canopy |     |
Enthought Canopy is a Python Platform or Python Distribution for Scientists
and Engineers.
| It is available | for Windows, | macOS | and Linux. |
| --------------- | ------------ | ----- | ---------- |
Canopy is freely available to all users under the Canopy license. Canopy pro-
vides access to several hundreds Python packages, including NumPy, SciPy,
| Pandas,      | Matplotlib, | and IPython.      |         |
| ------------ | ----------- | ----------------- | ------- |
| In addition, | we have     | the Canopy Python | Editor. |
Enthought Canopy is a competitor to the Anaconda Python Distribution. It is
| a matter | of taste who | you prefer. |     |
| -------- | ------------ | ----------- | --- |
Web:
https://www.enthought.com/product/canopy/
92

Part IV
Python Editors
93

| Chapter |     | 16      |     |     |     |
| ------- | --- | ------- | --- | --- | --- |
| Python  |     | Editors |     |     |     |
An Editor is a program where you create your code (and where you can run
and test it). Most Editors have also features for Debugging and IntelliSense.
In theory, you can use Windows Notepad for creating Python programs, but
in practice it is impossible to create programs without having an editor with
| Debugging, | IntelliSense, | color | formatting, | etc. |     |
| ---------- | ------------- | ----- | ----------- | ---- | --- |
For simple Python programs you can use the IDLE Editor, but for more ad-
| vanced   | programs a better | editor   | is recommended. |     |     |
| -------- | ----------------- | -------- | --------------- | --- | --- |
| Examples | of Python         | Editors: |                 |     |     |
• Spyder
| • Visual | Studio Code |     |     |     |     |
| -------- | ----------- | --- | --- | --- | --- |
• Thonny
| • Visual | Studio |     |     |     |     |
| -------- | ------ | --- | --- | --- | --- |
• PyCharm
• Wing
•
JupyterNotebook
| We will | give an overview | of these | Code | Editors in | the next chapters. |
| ------- | ---------------- | -------- | ---- | ---------- | ------------------ |
I guess hundreds of different editors can be used for Python Programming, ei-
ther out of the box or if you install an additional Extension that makes sure
| you can | use Python | in that editor. |     |     |     |
| ------- | ---------- | --------------- | --- | --- | --- |
IfyoualreadyhaveafavoriteCodeEditor, itisagoodchangeyoucanusethat
| one for | Python programming. |     |     |     |     |
| ------- | ------------------- | --- | --- | --- | --- |
Which editor you should use depends on your background, what kind of code
editors you have used previously, your programming skills, what your are going
94

| to develop | in Python, | etc. |     |
| ---------- | ---------- | ---- | --- |
If you are familiar with MATLAB, Spyder is recommended. Also, if you want
to use Python for numerical calculations and computations, Spyder is a good
choice.
If you want to create Web Applications or other kinds of Applications, other
| Editors | are probably better | to use. |     |
| ------- | ------------------- | ------- | --- |
For Internet of Things Applications, simple editors like Visual Studio Code or
Thonny may be good choices. Thonny is also the default editor on the Rasp-
| berry Pi   | OS, which is    | popular Internet | of Things platform. |
| ---------- | --------------- | ---------------- | ------------------- |
| For a list | of ”Best Python | Editors”,        | see [15].           |
95

| Chapter | 17  |     |     |
| ------- | --- | --- | --- |
Spyder
| Spyder - | short for ”Scientific | PYthon | Development EnviRonment”. |
| -------- | --------------------- | ------ | ------------------------- |
Spyderisanopensourcecross-platformintegrateddevelopmentenvironment(IDE)
| for scientific | programming     | in the Python    | language.         |
| -------------- | --------------- | ---------------- | ----------------- |
|                |                 | Figure 17.1:     | Spyder Editor     |
| The Spyder     | editor consists | of the following | parts or windows: |
•
| Code | Editor window |     |     |
| ---- | ------------- | --- | --- |
•
| iPython | Console | window |     |
| ------- | ------- | ------ | --- |
96

•
| Variable | Explorer |     |     |     |
| -------- | -------- | --- | --- | --- |
•
etc.
Web:
https://www.spyder-ide.org
If you have used MATLAB previously or want to use Python for scientific use,
Spyder is a good choice. it is easy to install using the Anaconda Distribution.
Web:
https://www.anaconda.com
| 17.1                     | Configuration |              |                          |          |
| ------------------------ | ------------- | ------------ | ------------------------ | -------- |
| Typically                | you want to   | show figures | and plots in separate    | windows. |
| Select Tools-Preferences |               | as shown     | in Figure 17.2.          |          |
|                          |               | Figure 17.2: | Python Tools-Preferences |          |
| Then select              | ”Automatic”   | as shown     | in Figure 17.3.          |          |
97

| Figure 17.3: | Python Preferences | window |
| ------------ | ------------------ | ------ |
98

| Chapter |              | 18     |     |        |        |      |
| ------- | ------------ | ------ | --- | ------ | ------ | ---- |
| Visual  |              | Studio |     | Code   |        |      |
| 18.1    | Introduction |        | to  | Visual | Studio | Code |
VisualStudioCodeisasimpleandeasytouseeditorthatcanbeusedformany
| different   | programming | languages.  |        |         |                |        |
| ----------- | ----------- | ----------- | ------ | ------- | -------------- | ------ |
|             | Figure      | 18.1: Using | Visual | Studio  | Code as Python | Editor |
| Right-Click | and         | select ”Run | Python | File in | Terminal”      |        |
Web:
https://code.visualstudio.com
Wikipedia:
| https://en.wikipedia.org/wiki/Visual |     |     |     | tudio | ode |     |
| ------------------------------------ | --- | --- | --- | ----- | --- | --- |
|                                      |     |     |     | S     | C   |     |
99

| 18.2 | Python | in Visual | Studio | Code |
| ---- | ------ | --------- | ------ | ---- |
In addition to Visual Studio Code you need to install the Python extension for
| Visual Studio | Code. |     |     |     |
| ------------- | ----- | --- | --- | --- |
You must install a Python interpreter yourself separately from the extension.
| For a quick | install, use | Python from | python.org. |     |
| ----------- | ------------ | ----------- | ----------- | --- |
https://www.python.org
Python is an interpreted language, and in order to run Python code and get
Python IntelliSense within Visual Studio Code, you must tell Visual Studio
| Code which | interpreter | to use. |     |     |
| ---------- | ----------- | ------- | --- | --- |
Web:
https://code.visualstudio.com/docs/languages/python
100

| Chapter | 19           |     |        |        |     |
| ------- | ------------ | --- | ------ | ------ | --- |
| Visual  | Studio       |     |        |        |     |
| 19.1    | Introduction | to  | Visual | Studio |     |
Microsoft Visual Studio is an integrated development environment (IDE) from
Microsoft. It is used to develop computer programs, as well as websites, web
apps,webservicesandmobileapps. Thedefault(main)programminglanguage
in Visual studio is C, but many other programming languages are supported.
| You could     | say Visual   | Studio is the | big brother | of Visual | Studio Code. |
| ------------- | ------------ | ------------- | ----------- | --------- | ------------ |
| Visual studio | is available | for Windows   | and         | macOS.    |              |
Visual Studio (from 2017), has integrated support for Python, it is called
| ”Python Support | in Visual | Studio”. |     |     |     |
| --------------- | --------- | -------- | --- | --- | --- |
Web:
https://visualstudio.microsoft.com
Wikipedia:
| https://en.wikipedia.org/wiki/Microsoft |     |     | V isual | S tudio |     |
| --------------------------------------- | --- | --- | ------- | ------- | --- |
Go to my Web Site to learn more about Visual Studio and C programming:
https://www.halvorsen.blog/
| Visual Studio | and C: |     |     |     |     |
| ------------- | ------ | --- | --- | --- | --- |
https://www.halvorsen.blog/documents/programming/csharp/
| 19.2      | Work with | Python         | in  | Visual | Studio |
| --------- | --------- | -------------- | --- | ------ | ------ |
| Work with | Python in | Visual Studio: |     |        |        |
https://docs.microsoft.com/visualstudio/python/
101

|        | Figure |        | 19.1: Using | Visual | Studio | as Python | Editor          |
| ------ | ------ | ------ | ----------- | ------ | ------ | --------- | --------------- |
| 19.2.1 | Make   | Visual |             | Studio | ready  | for       | Python Program- |
ming
Visual Studio is mainly for Windows. A MacOS version of Visual Studio do
| exists, but | it has | lot less | features | than | the Windows | edition. |     |
| ----------- | ------ | -------- | -------- | ---- | ----------- | -------- | --- |
Note that Python support is available only on Visual Studio for Windows. If
you use Mac and Linux, you need to use Visual Studio Code. You could say
| Visual Studio | Code | is  | a down-scaled |     | version of | Visual | Studio. |
| ------------- | ---- | --- | ------------- | --- | ---------- | ------ | ------- |
Visual Studio (from 2017), has integrated support for Python, it is called
”Python Support in Visual Studio”. Even if it is integrated, you need to manu-
ally select which components you want to install on your computer. Make sure
| to download | and | run | the latest | Visual | Studio 2017 | installer | for Windows. |
| ----------- | --- | --- | ---------- | ------ | ----------- | --------- | ------------ |
when you run the Visual Studio installer (either for the first time or if you
already have installed Visual Studio 2017 and want to modify it) the window
| shown in | Figure | 19.2 | pops up. |     |     |     |     |
| -------- | ------ | ---- | -------- | --- | --- | --- | --- |
Theinstallerpresentsyouwithalistofsocalledworkloads,whicharegroupsof
related options for specific development areas. For Python, select the ”Python
| development” | workload |     | and         | select | Install (Figure | 19.3). |     |
| ------------ | -------- | --- | ----------- | ------ | --------------- | ------ | --- |
| 19.2.2       | Python   |     | Interactive |        |                 |        |     |
To quickly test Python support, launch Visual Studio, press Alt+I (or select
from the menu: Tools - Python - Python Interactive Window) to open the
| Python Interactive |           | window. |            | See Figure | 19.4. |     |     |
| ------------------ | --------- | ------- | ---------- | ---------- | ----- | --- | --- |
| Lets write         | something |         | like this: |            |       |     |     |
| >>> a =            | 2         |         |            |            |       |     |     |
1
102

|       | Figure | 19.2: Installing | Python       | Extension   | for Visual Studio |
| ----- | ------ | ---------------- | ------------ | ----------- | ----------------- |
|       |        | Figure           | 19.3: Python | Development | Workload          |
| >>> b | = 5    |                  |              |             |                   |
2
| >>> x | = 3 |     |     |     |     |
| ----- | --- | --- | --- | --- | --- |
3
| 4 >>> y | = a∗x | + b |     |     |     |
| ------- | ----- | --- | --- | --- | --- |
5 >>> y
| 19.2.3   | New | Python        | Project  |              |     |
| -------- | --- | ------------- | -------- | ------------ | --- |
| Lets see | how | we can create | a Python | Application. |     |
Startbyselectfromthemenu: File-New-Project... TheNewProjectwindow
| pops up. | See | Figure 19.5. |     |     |     |
| -------- | --- | ------------ | --- | --- | --- |
We can create an ordinary Python Application (one or more Python Scripts),
we can choose to create a Web Application using either Web Frameworks like
Django or Flask, or we can create different Desktop GUI applications. We can
| also create | Games.  |        |             |             |                  |
| ----------- | ------- | ------ | ----------- | ----------- | ---------------- |
| Example     | 19.2.1. | Python | Hello World | Application | in Visual Studio |
103

|     |     | Figure 19.4: | Python Interactive |     |
| --- | --- | ------------ | ------------------ | --- |
We start by creating a basic Hello World Python Application. See Figure 19.1.
SelectFile-New-Project... TheNewProjectwindowpopsup. SeeFigure19.5.
| Name the | project, e.g, | ”PythonApplication1”. |     |     |
| -------- | ------------- | --------------------- | --- | --- |
In the Project Explorer, open the ”PythonApplication1.py” file and enter the
| following      | Python code: |     |     |     |
| -------------- | ------------ | --- | --- | --- |
| 1 print(”Hello | World”)      |     |     |     |
HitF5(ourclickthegreenarrow)inordertorunorexecutethePythonprogram.
| You can | also right click | on the file | and select ”Start | without Debugging”. |
| ------- | ---------------- | ----------- | ----------------- | ------------------- |
[End of Example]
| Example | 19.2.2. Visual | Studio Python | Plotting |     |
| ------- | -------------- | ------------- | -------- | --- |
CreateanewPythonFilebyrightclickintheSolutionExplorerandselectAdd
| - New Item...            | and then         | select ”Empty | Python File”. |     |
| ------------------------ | ---------------- | ------------- | ------------- | --- |
| Enter the                | following Python | Code:         |               |     |
| import matplotlib.pyplot |                  | as plt        |               |     |
1
| import numpy | as np |     |     |     |
| ------------ | ----- | --- | --- | --- |
2
3
| 4 xstart =  | 0       |     |     |     |
| ----------- | ------- | --- | --- | --- |
| 5 xstop =   | 2∗np.pi |     |     |     |
| 6 increment | = 0.1   |     |     |     |
7
| 8 x = np.arange(xstart |     | ,xstop,increment) |     |     |
| ---------------------- | --- | ----------------- | --- | --- |
9
y = np.sin(x)
10
11
| plt.plot(x, | y)  |     |     |     |
| ----------- | --- | --- | --- | --- |
12
plt. title(’y=sin(x)’)
13
104

|     |     | Figure | 19.5: | New | Python Project |     |
| --- | --- | ------ | ----- | --- | -------------- | --- |
plt.xlabel(’x’)
14
plt.ylabel(’y’)
15
16 plt.grid()
| 17 plt.axis([0, | 2∗np.pi, |     | −1, 1]) |     |     |     |
| --------------- | -------- | --- | ------- | --- | --- | --- |
18 plt.show()
| See also | Figure 19.6. |     |     |     |     |     |
| -------- | ------------ | --- | --- | --- | --- | --- |
Make sure to select proper Python Environment. See Figure (19.7). Visual
| Studio supports | multiple |     | Python | Environments. |     |     |
| --------------- | -------- | --- | ------ | ------------- | --- | --- |
In this example we use the Matplotlib package for plotting, so we need to have
that package installed on the computer. You can install the Matplotlib package
| in different | Python | Environments. |     |     |     |     |
| ------------ | ------ | ------------- | --- | --- | --- | --- |
I have installed the Matplotlib package as part of the Anaconda distribution
| setup, so | I select ”Anaconda |     | x.x.x” | in  | the Python Environments | window. |
| --------- | ------------------ | --- | ------ | --- | ----------------------- | ------- |
If you haven’t installed the Matplotlib package yet (either as part of Anaconda
ormanuallyusingPIP),youcanalsoeasilyinstallPythonpackagesfromVisual
| studio. | See Figure | 19.8. |     |     |     |     |
| ------- | ---------- | ----- | --- | --- | --- | --- |
You can also easily see which Python Packages that are installed for the differ-
| ent Python | Environments. |     | See | Figure | 19.9. |     |
| ---------- | ------------- | --- | --- | ------ | ----- | --- |
105

|     | Figure 19.6: | Python Plotting | Example | with Visual Studio |
| --- | ------------ | --------------- | ------- | ------------------ |
The good thing about using Visual Studio is that you have a graphical user
interface for everything, you don’t need to use the Command window etc. for
| installing | Python Packages, | etc. |     |     |
| ---------- | ---------------- | ---- | --- | --- |
HitF5(ourclickthegreenarrow)inordertorunorexecutethePythonprogram.
| You can | also right    | click on the file   | and select ”Start | without Debugging”. |
| ------- | ------------- | ------------------- | ----------------- | ------------------- |
| We get  | the following | results, see Figure | 19.10.            |                     |
[End of Example]
106

| Figure       | 19.7: Select   | your Python Environment |               |
| ------------ | -------------- | ----------------------- | ------------- |
| Figure 19.8: | Install Python | Packages from           | Visual Studio |
107

Figure19.9: InstallingPythonPackagesfordifferentPythonEnvironmentsfrom
Visual Studio
| Figure 19.10: | Python Plotting | Example with | Visual Studio |
| ------------- | --------------- | ------------ | ------------- |
108

| Chapter | 20  |     |     |     |
| ------- | --- | --- | --- | --- |
PyCharm
PyCharm is cross-platform, with Windows, macOS and Linux versions. The
Community Edition is free to use, while the Professional Edition (paid version)
| has some extra | features.       |               |        |        |
| -------------- | --------------- | ------------- | ------ | ------ |
| The PyCharm    | Editor is shown | in Figure     | 20.1.  |        |
|                | Figure          | 20.1: PyCharm | Python | Editor |
Web:
https://www.jetbrains.com/pycharm/
Wikipedia:
https://en.wikipedia.org/wiki/PyCharm
Anaconda and JetBrains also have a collaboration and offer what they call Py-
| Charm for | Anaconda. You | can download | it here: |     |
| --------- | ------------- | ------------ | -------- | --- |
109

https://www.jetbrains.com/pycharm/promo/anaconda/
We have code editors like Visual Studio and Visual Studio Code which can be
used for many different programming languages by installing different types of
plugins.
Editors like Spyder and PyCharm are tailor-made editors for the Python lan-
guage.
Spyder is light-weight IDE typically used for scientific use. PyCharm on the
other hand is full-blown IDE for software development in general by using the
Python language. It supports many plugins, it’s easier to program Django, etc.
110

| Chapter | 21     |     |     |
| ------- | ------ | --- | --- |
| Wing    | Python | IDE |     |
The Wing Python IDE family of integrated development environments (IDEs)
fromWingwarewerecreatedspecificallyforthePythonprogramminglanguage.
| 3 different version | of Wing exists | [12]: |     |
| ------------------- | -------------- | ----- | --- |
• Wing 101 – a very simplified free version, for teaching beginning pro-
grammers
•
| Wing | Personal–freeversionthatomitssomefeatures,forstudentsand |     |     |
| ---- | -------------------------------------------------------- | --- | --- |
hobbyists
• Wing Pro – a full-featured commercial (paid) version, for professional
programmers
|     | Figure | 21.1: Wing Python | IDE |
| --- | ------ | ----------------- | --- |
Web:
https://wingware.com
111

Wikipedia:
https://en.wikipedia.org/wiki/Wing DE
I
112

Chapter 22
Jupyter Notebook
TheJupyterNotebookisanopen-sourcewebapplicationthatallowsyoutocre-
ate and share documents that contain live code, equations, visualizations and
text.
TheNotebookhassupportforover40programminglanguages,includingPython.
Figure 22.1: Jupyter Notebook [16]
Web:
http://jupyter.org
Wikipedia:
https://en.wikipedia.org/wiki/Project upyter
J
113

| 22.1 | JupyterHub |     |     |     |     |     |     |
| ---- | ---------- | --- | --- | --- | --- | --- | --- |
JupyterHub is a multi-user version of the notebook designed for companies,
| classrooms | and  | research labs | [17]. |         |     |           |     |
| ---------- | ---- | ------------- | ----- | ------- | --- | --------- | --- |
| JupyterHub | runs | in the cloud  | or    | on your | own | hardware. |     |
JupyterHubisopen-sourceanddesignedtoberunonavarietyofinfrastructure.
This includes commercial cloud providers, virtual machines, or even your own
laptop hardware.
Web:
http://jupyter.org/hub
| 22.2 | Microsoft |     | Azure | Notebooks |     |     |     |
| ---- | --------- | --- | ----- | --------- | --- | --- | --- |
Microsoft Azure Notebooks is a version of Jupyter Notebook from Microsoft.
The good thing about Microsoft Azure Notebooks is that you have the infras-
tructure and everything up and running ready for you to use. You can use it
| for free | as well. |     |     |     |     |     |     |
| -------- | -------- | --- | --- | --- | --- | --- | --- |
Web:
https://notebooks.azure.com
| Example     | 22.2.1. | Example     | Name  |          |           |           |            |
| ----------- | ------- | ----------- | ----- | -------- | --------- | --------- | ---------- |
| Figure 22.2 | shows   | an overview | of    | my Azure | Notebook  | Projects. |            |
|             |         | Figure      | 22.2: | Azure    | Notebook  | Projects  |            |
| Figure 22.3 | shows   | an overview | of    | my Azure | Notebook  | Project   | Notebooks. |
| Figure 22.4 | shows   | an example  | of    | a simple | Notebook. |           |            |
[End of Example]
114

| Figure 22.3: | Azure Notebook       | Project Notebooks |
| ------------ | -------------------- | ----------------- |
| Figure       | 22.4: Azure Notebook | Example           |
115

Part V
Python for Mathematics
Applications
116

| Chapter     |               | 23   |     |              |               |        |
| ----------- | ------------- | ---- | --- | ------------ | ------------- | ------ |
| Mathematics |               |      |     |              | in            | Python |
| Python      | is a powerful | tool | for | mathematical | calculations. |        |
If you are looking for similar using MATLAB, please take a look at these re-
sources:
https://www.halvorsen.blog/documents/programming/matlab/
| 23.1 | Basic | Math |     | Functions |     |     |
| ---- | ----- | ---- | --- | --------- | --- | --- |
ThePython Standard Library consistsofdifferentmodulesforhandlingfile
I/O,basicmathematics,etc. Youdon’tneedtoinstalltheseseparately,butyou
need to important them when you want to use some of these modules or some
| of the functions |     | within | these modules. |     |     |     |
| ---------------- | --- | ------ | -------------- | --- | --- | --- |
In this chapter we will focus on the math module that is part of the Python
| Standard | Library. |     |     |     |     |     |
| -------- | -------- | --- | --- | --- | --- | --- |
The math module has all the basic math functions you need, such as: Trigono-
metric functions: sin(x), cos(x), etc. Logarithmic functions: log(), log10(), etc.
| Constants | like    | pi, e, inf, | nan, | etc. etc.   |     |     |
| --------- | ------- | ----------- | ---- | ----------- | --- | --- |
| Example   | 23.1.1. | Using       | the  | math module |     |     |
We create some basic examples how to use a Library, a Package or a Module:
| If we need | only   | the sin() | function | we  | can do | like this: |
| ---------- | ------ | --------- | -------- | --- | ------ | ---------- |
| from math  | import | sin       |          |     |        |            |
1
2
3 x = 3.14
4 y = sin(x)
5
6 print(y)
| If we need | a few | functions | we  | can do | like this |     |
| ---------- | ----- | --------- | --- | ------ | --------- | --- |
117

1 from math import sin , cos
2
3 x = 3.14
4 y = sin(x)
5 print(y)
6
7 y = cos(x)
8 print(y)
If we need many functions we can do like this:
1 from math import ∗
2
3 x = 3.14
4 y = sin(x)
5 print(y)
6
7 y = cos(x)
8 print(y)
We can also use this alternative:
1 import math
2
3 x = 3.14
4 y = math.sin(x)
5
6 print(y)
We can also write it like this:
1 import math as mt
2
3 x = 3.14
4 y = mt.sin(x)
5
6 print(y)
[End of Example]
There are advantages and disadvantages with the different approaches. In your
program you may need to use functions from many different modules or pack-
ages. If you import the whole module instead of just the function(s) you need
you use more of the computer memory.
Very often we also need to import and use multiple libraries where the different
libraries have some functions with the same name but different use.
OtherusefulmodulesinthePython Standard Libraryarestatistics(where
you have functions like mean(), stdev(), etc.)
For more information about the functions in the Python Standard Library,
see:
https://docs.python.org/3/library/
118

| 23.1.1 | Exercises |     |     |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- | --- | --- |
Below you find different self-paced Exercises that you should go through and
solve on your own. The only way to learn Python is to do lots of Exercises!
| Exercise          | 23.1.1. | Create Mathematical |       | Expressions            |              | in Python |             |
| ----------------- | ------- | ------------------- | ----- | ---------------------- | ------------ | --------- | ----------- |
| Create a function |         | that calculates     |       | the following          | mathematical |           | expression: |
|                   |         |                     | =3x2+ | (cid:112) x2+y2+eln(x) |              |           |             |
z (23.1)
| Test with different |           | values for      | x and | y.           |     |             |                   |
| ------------------- | --------- | --------------- | ----- | ------------ | --- | ----------- | ----------------- |
|                     |           |                 |       |              |     |             | [End of Exercise] |
| Exercise            | 23.1.2.   | Create advanced |       | Mathematical |     | Expressions | in Python         |
| Create the          | following | expression      | in    | Python:      |     |             |                   |
ln(ax2+bx+c)−sin(ax2+bx+c)
f(x)= (23.2)
4πx2+cos(x−2)(ax2+bx+c)
| Given a=1,b=3,c=5 |        | Find                  | f(9) |      |           |        |          |
| ----------------- | ------ | --------------------- | ---- | ---- | --------- | ------ | -------- |
| (The answer       | should | be f(9)=0.0044)       |      |      |           |        |          |
| Tip! You should   |        | split the expressions |      | into | different | parts, | such as: |
=ax2+bx+c
poly
num=...
den=...
f =...
This makes the expression simpler to read and understand, and you minimize
| the risk of | making  | an error       | while | typing the    | expression | in                | Python. |
| ----------- | ------- | -------------- | ----- | ------------- | ---------- | ----------------- | ------- |
| When you    | got the | correct answer |       | try to change | to,        | e.g., a=2,b=8,c=6 |         |
Find f(9)
|          |         |            |     |     |     |     | [End of Exercise] |
| -------- | ------- | ---------- | --- | --- | --- | --- | ----------------- |
| Exercise | 23.1.3. | Pythagoras |     |     |     |     |                   |
119

|            |         |     | Figure      | 23.1: Right-angled | triangle |
| ---------- | ------- | --- | ----------- | ------------------ | -------- |
| Pythagoras | theorem | is  | as follows: |                    |          |
|            |         |     |             | c2 =a2+b2          | (23.3)   |
Create a function that uses Pythagoras to calculate the hypotenuse of a right-
| angled triangle |     | (Figure | 23.1), | e.g.: |     |
| --------------- | --- | ------- | ------ | ----- | --- |
1 def pythagoras(a,b)
2 ...
3 ...
| 4 return | c   |     |     |     |     |
| -------- | --- | --- | --- | --- | --- |
[End of Exercise]
| Exercise  | 23.1.4. | Albert   | Einstein |                  |        |
| --------- | ------- | -------- | -------- | ---------------- | ------ |
| Given the | famous  | equation | from     | Albert Einstein: |        |
|           |         |          |          | E =mc2           | (23.4) |
385x1024J/s
| The sun | radiates |     |     | of energy. |     |
| ------- | -------- | --- | --- | ---------- | --- |
Calculatehowmuchofthemassonthesunisusedtocreatethisenergyperday.
How many years will it take to convert all the mass of the sun completely? Do
weneedtoworryifthesunwillbeusedupinourgenerationorthenext? justify
the answer.
2x1030kg.
| The mass | of the | sun is |     |     |     |
| -------- | ------ | ------ | --- | --- | --- |
120

|          |         |                  |      |     | [End of | Exercise] |
| -------- | ------- | ---------------- | ---- | --- | ------- | --------- |
| Exercise | 23.1.5. | Cylinder Surface | Area |     |         |           |
Create a function that finds the surface area of a cylinder based on the height
| (h) | and the radius | (r) of the | cylinder. See | Figure ??. |     |     |
| --- | -------------- | ---------- | ------------- | ---------- | --- | --- |
Figure 23.2: cylinder
|        |              |     |               |     | [End of | Exercise] |
| ------ | ------------ | --- | ------------- | --- | ------- | --------- |
| 23.2   | Statistics   |     |               |     |         |           |
| 23.2.1 | Introduction |     | to Statistics |     |         |           |
| Mean   | or average:  |     |               |     |         |           |
The mean is the sum of the data divided by the number of data points. It is
| commonly | called    | ”the average”. |           |     |          |        |
| -------- | --------- | -------------- | --------- | --- | -------- | ------ |
| Formula  | for mean: |                |           |     |          |        |
|          |           | x +x           | +x +...+x |     | 1 N      |        |
|          |           | 1              | 2 3       | N   | (cid:88) |        |
|          |           | x¯=            |           | =   | x i      | (23.5) |
|          |           |                | N         |     | N        |        |
i=1
| Example | 23.2.1.       | Mean     |                |          |     |     |
| ------- | ------------- | -------- | -------------- | -------- | --- | --- |
| Given   | the following | dataset: | 2.2, 4.5, 6.2, | 3.6, 2.6 |     |     |
Mean:
N
|     | 1   | (cid:88) 2.2+4.5+6.2+3.6+2.6 |     |     | 19.1    |        |
| --- | --- | ---------------------------- | --- | --- | ------- | ------ |
|     | x¯= | x =                          |     |     | = =3.82 | (23.6) |
i
|     | N   |     | 5   |     | 5   |     |
| --- | --- | --- | --- | --- | --- | --- |
i=1
121

[End of Example]
Variance:
| Variance | is a | measure | of the variation |     | in a data | set. |     |
| -------- | ---- | ------- | ---------------- | --- | --------- | ---- | --- |
1 N
|     |     |     |         |     | (cid:88) | −x¯)2 |        |
| --- | --- | --- | ------- | --- | -------- | ----- | ------ |
|     |     |     | var(x)= |     | (x       |       | (23.7) |
|     |     |     |         | N   | i        |       |        |
i=1
| Standard | deviation: |     |     |     |     |     |     |
| -------- | ---------- | --- | --- | --- | --- | --- | --- |
The standard deviation is a measure of the spread of the values in a dataset
orthevalueofarandomvariable. Itisdefinedasthesquarerootofthevariance.
(cid:118)
|     |     |          |     |       | (cid:117)   | N        |        |
| --- | --- | -------- | --- | ----- | ----------- | -------- | ------ |
|     |     |          |     | √     | (cid:117) 1 | (cid:88) |        |
|     |     | std(x)=σ |     | = var | =(cid:116)  | (x −x¯)2 | (23.8) |
i
N
i=1
| We typically |            | use the    | symbol σ  | for standard | deviation. |     |     |
| ------------ | ---------- | ---------- | --------- | ------------ | ---------- | --- | --- |
| We have      | that       | σ2 =var(x) |           |              |            |     |     |
| 23.2.2       | Statistics |            | functions | in           | Python     |     |     |
| Mathematical |            | statistics | functions | in Python:   |            |     |     |
https://docs.python.org/3/library/statistics.html
| statistics | is part | of the | The Python | Standard |     | Library. |     |
| ---------- | ------- | ------ | ---------- | -------- | --- | -------- | --- |
For more information about the functions in the Python Standard Library,
see:
https://docs.python.org/3/library/
Example 23.2.2. Statistics using the statistics module in Python Standard
Library
Belowyoufindsomeexampleshowtousesomeofthestatisticsfunctionsinthe
| statistics | module     | in  | Python Standard | Library: |     |     |     |
| ---------- | ---------- | --- | --------------- | -------- | --- | --- | --- |
| 1 import   | statistics |     | as st           |          |     |     |     |
2
[−1.0,
| 3 data = |     | 2.5, | 3.25, | 5.75] |     |     |     |
| -------- | --- | ---- | ----- | ----- | --- | --- | --- |
4
| 5 #Mean | or Average |     |     |     |     |     |     |
| ------- | ---------- | --- | --- | --- | --- | --- | --- |
m = st.mean(data)
6
print(m)
7
8
| # Standard |     | Deviation |     |     |     |     |     |
| ---------- | --- | --------- | --- | --- | --- | --- | --- |
9
| 10 st dev | = st.stdev(data) |     |     |     |     |     |     |
| --------- | ---------------- | --- | --- | --- | --- | --- | --- |
122

| 11 print(st | dev) |     |     |     |     |
| ----------- | ---- | --- | --- | --- | --- |
12
13 # Median
14 med = st.median(data)
print(med)
15
16
# Variance
17
var = st.variance(data)
18
19 print(var)
|     | Listing | 23.1: | Statistics | functions | in Python |
| --- | ------- | ----- | ---------- | --------- | --------- |
[End of Example]
IMPORTANT: Do not name your file ”statistics.py” since the import will be
confusedandthrowtheerrorsofthelibrarynotexistingandthemeanfunction
not existing.
You can also use the NumPy Library. NumPy is the fundamental package for
| scientific computing | with             | Python. |       |          |     |
| -------------------- | ---------------- | ------- | ----- | -------- | --- |
| Here you             | find an overview | of the  | NumPy | library: |     |
http://www.numpy.org
| Example | 23.2.3. Statistics | using | the | NumPy | Library |
| ------- | ------------------ | ----- | --- | ----- | ------- |
Below you find some examples how to use some of the statistics functions in
NumPy:
| 1 import numpy | as np |     |     |     |     |
| -------------- | ----- | --- | --- | --- | --- |
2
| data = [−1.0, | 2.5, | 3.25, 5.75] |     |     |     |
| ------------- | ---- | ----------- | --- | --- | --- |
3
4
| #Mean or | Average |     |     |     |     |
| -------- | ------- | --- | --- | --- | --- |
5
m = np.mean(data)
6
print(m)
7
8
| 9 # Standard | Deviation    |     |     |     |     |
| ------------ | ------------ | --- | --- | --- | --- |
| 10 st dev =  | np.std(data) |     |     |     |     |
| 11 print(st  | dev)         |     |     |     |     |
12
# Median
13
med = np.median(data)
14
print(med)
15
16
| 17 # Minimum | Value |     |     |     |     |
| ------------ | ----- | --- | --- | --- | --- |
18 minv = np.min(data)
19 print(minv)
20
| 21 # Maxumum | Value |     |     |     |     |
| ------------ | ----- | --- | --- | --- | --- |
maxv = np.max(data)
22
print(maxv)
23
|     | Listing | 23.2: Statistics | using | the | NumPy Library |
| --- | ------- | ---------------- | ----- | --- | ------------- |
123

|          |         |        |      |     |            |        |           | [End of Example] |
| -------- | ------- | ------ | ---- | --- | ---------- | ------ | --------- | ---------------- |
| Exercise | 23.2.1. | Create | your | own | Statistics | Module | in Python |                  |
Using the built-in functions in the Python Standard Library or the NumPy li-
brary is straightforward.
In order to get a deeper understanding of the mathematics behind these func-
tions and to learn more Python programming, you should create your own
| Statistics | Module | in  | Python. |     |     |     |     |     |
| ---------- | ------ | --- | ------- | --- | --- | --- | --- | --- |
Create your own Statistics Module in Python (e.g., ”mystatistics.py) and then
create a Python Script (e.g., ”testmystatistics.py) where you test these func-
tions.
Youshouldatleastimplementfunctionsformean,variance,standarddeviation,
| minimum | and           | maximum. |               |           |            |       |           |                   |
| ------- | ------------- | -------- | ------------- | --------- | ---------- | ----- | --------- | ----------------- |
|         |               |          |               |           |            |       |           | [End of Exercise] |
| 23.3    | Trigonometric |          |               | Functions |            |       |           |                   |
| Python  | offers lots   | of       | Trigonometric |           | functions, | e.g., | sin, cos, | tan, etc.         |
Note! Mostofthetrigonometricfunctionsrequirethattheangleisexpressedin
radians.
| Example  | 23.3.1. | Trigonometric |     | Functions |     | in Math | module |     |
| -------- | ------- | ------------- | --- | --------- | --- | ------- | ------ | --- |
| 1 import | math as | mt            |     |           |     |         |        |     |
2
2∗mt.pi
3 x =
4
y = mt.sin(x)
5
print(y)
6
7
y = mt.cos(x)
8
print(y)
9
10
11 y = mt.tan(x)
12 print(y)
|         | Listing   | 23.3: | Trigonometric |        | Functions |        | in Math  | module   |
| ------- | --------- | ----- | ------------- | ------ | --------- | ------ | -------- | -------- |
| Here we | have used | the   | Math          | module | in the    | Python | Standard | Library. |
For more information about the functions in the Python Standard Library,
see:
https://docs.python.org/3/library/index.html
124

[End of Example]
| Example | 23.3.2. Plotting | Trigonometric | Functions |     |
| ------- | ---------------- | ------------- | --------- | --- |
In the example above we used some of the trigonometric functions in basic cal-
culations.
| Lets see if | we are able to | plot these functions. |     |     |
| ----------- | -------------- | --------------------- | --- | --- |
| import math | as mt          |                       |     |     |
1
| import matplotlib.pyplot |     | as plt |     |     |
| ------------------------ | --- | ------ | --- | --- |
2
3
| 4 xdata = | []  |     |     |     |
| --------- | --- | --- | --- | --- |
| 5 ydata = | []  |     |     |     |
6
| 7 for x in | range(0, 10): |     |     |     |
| ---------- | ------------- | --- | --- | --- |
xdata.append(x)
8
| y = mt.sin(x) |     |     |     |     |
| ------------- | --- | --- | --- | --- |
9
ydata.append(y)
10
11
| plt.plot(xdata, | ydata) |     |     |     |
| --------------- | ------ | --- | --- | --- |
12
13 plt.show()
|     | Listing 23.4: | Plotting Trigonometric |     | Functions |
| --- | ------------- | ---------------------- | --- | --------- |
Intheexamplewehaveplottedsin(x),wecaneasilyextendtheprogramtoplot
cos(x), etc.
For more information about the functions in the Python Standard Library,
see:
https://docs.python.org/3/library/index.html
[End of Example]
| Example | 23.3.3. Trigonometric | Functions | using | NumPy |
| ------- | --------------------- | --------- | ----- | ----- |
The problem with using the Trigonometric functions in the the Math module
from the Python Standard Library is that they don’t handle an array as input.
We will use the NumPy library instead because they handle arrays, in addition
| to all the                 | handy functionality | in the NumPy | library. |     |
| -------------------------- | ------------------- | ------------ | -------- | --- |
| 1 import numpy             | as np               |              |          |     |
| 2 import matplotlib.pyplot |                     | as plt       |          |     |
3
| 4 xstart = | 0   |     |     |     |
| ---------- | --- | --- | --- | --- |
2∗np.pi
5 xstop =
| increment | = 0.1 |     |     |     |
| --------- | ----- | --- | --- | --- |
6
7
| x = np.arange(xstart | ,xstop,increment) |     |     |     |
| -------------------- | ----------------- | --- | --- | --- |
8
9
y = np.sin(x)
10
125

| 11 plt.plot(x, | y)  |     |     |     |     |
| -------------- | --- | --- | --- | --- | --- |
12 plt. title(’y=sin(x)’)
13 plt.xlabel(’x’)
14 plt.ylabel(’y’)
plt.grid()
15
| plt.axis([0, | 2∗np.pi, | −1, 1]) |     |     |     |
| ------------ | -------- | ------- | --- | --- | --- |
16
plt.show()
17
18
19 y = np.cos(x)
| 20 plt.plot(x, | y)  |     |     |     |     |
| -------------- | --- | --- | --- | --- | --- |
21 plt. title(’y=cos(x)’)
22 plt.xlabel(’x’)
23 plt.ylabel(’y’)
plt.grid()
24
| plt.axis([0, | 2∗np.pi, | −1, 1]) |     |     |     |
| ------------ | -------- | ------- | --- | --- | --- |
25
plt.show()
26
27
y = np.tan(x)
28
| 29 plt.plot(x, | y)  |     |     |     |     |
| -------------- | --- | --- | --- | --- | --- |
30 plt. title(’y=tan(x)’)
31 plt.xlabel(’x’)
32 plt.ylabel(’y’)
33 plt.grid()
| plt.axis([0, | 2∗np.pi, | −1, 1]) |     |     |     |
| ------------ | -------- | ------- | --- | --- | --- |
34
plt.show()
35
|             | Listing | 23.5: Trigonometric | Functions          | using NumPy |          |
| ----------- | ------- | ------------------- | ------------------ | ----------- | -------- |
| This Python | script  | gives the plots     | as shown in Figure | 23.3.       |          |
|             |         |                     |                    | [End of     | Example] |
Exercise 23.3.1. Create Python functions for converting between radians an
degrees
Since most of the trigonometric functions require that the angle is expressed in
radians, we will create our own functions in order to convert between radians
and degrees.
It is quite easy to convert from radians to degrees or from degrees to radians.
| We have | that: |                          |     |     |        |
| ------- | ----- | ------------------------ | --- | --- | ------ |
|         |       | 2π[radians]=360[degrees] |     |     | (23.9) |
This gives:
180
|     |     | d[degrees]=r[radians]×( |     | )   | (23.10) |
| --- | --- | ----------------------- | --- | --- | ------- |
π
and
π
|     |     | r[radians]=d[degrees]×( |     | )   | (23.11) |
| --- | --- | ----------------------- | --- | --- | ------- |
180
Create two functions that convert from radians to degrees (r2d(x)) and from
| degrees to | radians | (d2r(x)) respectively. |     |     |     |
| ---------- | ------- | ---------------------- | --- | --- | --- |
126

| These    | functions | should   | be            | saved | in one Python | file     | .py.      |           |
| -------- | --------- | -------- | ------------- | ----- | ------------- | -------- | --------- | --------- |
| Test the | functions | to       | make          | sure  | that they     | work as  | expected. |           |
|          |           |          |               |       |               |          | [End of   | Exercise] |
| Exercise | 23.3.2.   |          | Trigonometric |       | functions     | on right | triangle  |           |
| Given    | right     | triangle | as shown      | in    | Figure 23.4.  |          |           |           |
Create a function that finds the angle A (in degrees) based on input arguments
| (a,c),     | (b,c) and | (a,b) | respectively. |     |            |           |              |     |
| ---------- | --------- | ----- | ------------- | --- | ---------- | --------- | ------------ | --- |
| Use, e.g., | a third   | input | “type”        | to  | define the | different | types above. |     |
Use you previous function r2d() to make sure the output of your function is in
| degrees  | and      | not in  | radians. |             |                 |     |     |         |
| -------- | -------- | ------- | -------- | ----------- | --------------- | --- | --- | ------- |
| Test the | function | to      | make     | sure it     | works properly. |     |     |         |
| Tip!     | We have  | that:   |          |             |                 |     |     |         |
|          |          |         |          |             | a               |     | a   |         |
|          |          |         | sin(A)=  |             | →A=arcsin(      |     | )   | (23.12) |
|          |          |         |          |             | c               |     | c   |         |
|          |          |         |          |             | b               |     | b   |         |
|          |          |         | cos(A)=  |             | →A=arccos(      |     | )   | (23.13) |
|          |          |         |          |             | c               |     | c   |         |
|          |          |         |          |             | a               |     | a   |         |
|          |          |         | tan(A)=  |             | →A=arctan(      |     | )   | (23.14) |
|          |          |         |          |             | b               |     | b   |         |
| We may   | also     | need to | use the  | Pythagoras’ | theorem:        |     |     |         |
c2 =a2+b2
(23.15)
1 >>> a=5
2 >>> b=8
|         | sqrt(a∗∗2 |     | b∗∗2) |     |     |     |     |     |
| ------- | --------- | --- | ----- | --- | --- | --- | --- | --- |
| 3 >>> c | =         |     | +     |     |     |     |     |     |
4
| >>> A | = right | triangle(a,c, |     | ’sin | ’)  |     |     |     |
| ----- | ------- | ------------- | --- | ---- | --- | --- | --- | --- |
5
A =
6
32.0054
7
8
| >>> A | = right | triangle(b,c, |     | ’cos’) |     |     |     |     |
| ----- | ------- | ------------- | --- | ------ | --- | --- | --- | --- |
9
10 A =
11 32.0054
| 12 >>> A | = right | triangle(a,b, |     | ’tan’) |     |     |     |     |
| -------- | ------- | ------------- | --- | ------ | --- | --- | --- | --- |
13 A =
14 32.0054
| We also | see | that the | answer | in this | case is | the same, | which is expected. |     |
| ------- | --- | -------- | ------ | ------- | ------- | --------- | ------------------ | --- |
127

[End of Exercise]
| Exercise  | 23.3.3.  | Law      | of Cosines |                  |         |                     |     |
| --------- | -------- | -------- | ---------- | ---------------- | ------- | ------------------- | --- |
| Given the | triangle | as shown |            | in Figure        | 23.5.   |                     |     |
| Create a  | function | where    | you        | find             | c using | the law of cosines. |     |
|           |          |          | c2         | =a2+b2−2abcos(C) |         |                     |     |
(23.16)
| Test the | functions | to make | sure | it  | works | properly. |     |
| -------- | --------- | ------- | ---- | --- | ----- | --------- | --- |
[End of Exercise]
| Exercise | 23.3.4. | Plotting |     | Trigonometric |     | Functions |     |
| -------- | ------- | -------- | --- | ------------- | --- | --------- | --- |
Plot sin(θ) and cos(θ) for 0 ≤ θ ≤ 2π in the same plot (both in the same plot
| and in 2 | different | subplots). |     |     |     |     |     |
| -------- | --------- | ---------- | --- | --- | --- | --- | --- |
Make sure to add labels and a legend and use different line styles and colors for
the plots.
[End of Exercise]
| 23.4         | Polynomials |              |                  |        |            |                |         |
| ------------ | ----------- | ------------ | ---------------- | ------ | ---------- | -------------- | ------- |
| A polynomial |             | is expressed | as:              |        |            |                |         |
|              |             | p(x)=p       |                  | xn+p   | xn−1+...+p | x+p            | (23.17) |
|              |             |              | 1                |        | 2          | n n+1          |         |
| where p      | 1 ,p 2 ,p   | 3 ,... are   | the coefficients |        | of the     | polynomial.    |         |
| We will      | use the     | Polynomial   |                  | Module | in the     | NumPy Package. |         |
Web:
https://numpy.org/doc/stable/reference/routines.polynomials.polynomial.html
Other Resources:
| Python                                  | Advanced | Course | Topics | -   | Polynomials: |                        |     |
| --------------------------------------- | -------- | ------ | ------ | --- | ------------ | ---------------------- | --- |
| https://www.python-course.eu/polynomial |          |        |        |     |              | c lass i n p ython.php |     |
128

129
| Figure 23.3: | Trigonometric | Functions |
| ------------ | ------------- | --------- |

Figure 23.4: Right Triangle
Figure 23.5: Law of Cosines
130

Part VI
Resources
131

| Chapter  | 24               |             |                |
| -------- | ---------------- | ----------- | -------------- |
| Python   | Resources        |             |                |
| Here you | find my Web page | with Python | resources [1]: |
https://www.halvorsen.blog/documents/programming/python/
| Python Home | Page [6]: |     |     |
| ----------- | --------- | --- | --- |
https://www.python.org
| Python Standard | Library | [18]: |     |
| --------------- | ------- | ----- | --- |
https://docs.python.org/3/library/index.html
| 24.1 | Python Distributions |     |     |
| ---- | -------------------- | --- | --- |
Anaconda:
https://www.anaconda.com
| 24.2 | Python Libraries |     |     |
| ---- | ---------------- | --- | --- |
NumPy Library:
http://www.numpy.org
SciPy Library:
https://www.scipy.org
| Matplotlib | Library: |     |     |
| ---------- | -------- | --- | --- |
https://matplotlib.org
| 24.3 | Python Editors |     |     |
| ---- | -------------- | --- | --- |
Spyder:
https://www.spyder-ide.org
132

| Visual studio | Code: |     |     |
| ------------- | ----- | --- | --- |
https://code.visualstudio.com
Visual Studio:
https://visualstudio.microsoft.com
PyCharm:
https://www.jetbrains.com/pycharm/
Wing:
https://wingware.com
Jupyter Notebook:
http://jupyter.org
| 24.4            | Python          | Tutorials |       |
| --------------- | --------------- | --------- | ----- |
| Python Tutorial | - w3schools.com |           | [13]: |
https://www.w3schools.com/python/
| The Python | Guru [19]: |     |     |
| ---------- | ---------- | --- | --- |
https://thepythonguru.com
| Wikibooks                       | - A Beginner’s | Python    | Tutorial: |
| ------------------------------- | -------------- | --------- | --------- |
| https://en.wikibooks.org/wiki/A |                |           | B eginner |
| TutorialsPoints                 | - Python       | Tutorial: |           |
https://www.tutorialspoint.com/python/
| The Hitchhiker’s | Guide | to Python: |     |
| ---------------- | ----- | ---------- | --- |
https://docs.python-guide.org
| Google’s | Python Class: |     |     |
| -------- | ------------- | --- | --- |
https://developers.google.com/edu/python/
| 24.5      | Python | in Visual | Studio |
| --------- | ------ | --------- | ------ |
| Work with | Python | in Visual | Studio |
https://docs.microsoft.com/visualstudio/python/
133

Bibliography
[1] H.-P. Halvorsen, “Technology blog - https://www.halvorsen.blog,” 2018.
[2] H.-P.Halvorsen,“Technologyblog-https://en.wikipedia.org/wiki/Python programming anguage),′′2018.
( l
[3] T. . T. P. Languages, “The 2018 top programming languages
| -                                                 |           | https://spectrum.ieee.org/at-work/innovation/the-2018-top- |                 |            |           |        |           |     |
| ------------------------------------------------- | --------- | ---------------------------------------------------------- | --------------- | ---------- | --------- | ------ | --------- | --- |
| programming-languages,”                           |           |                                                            | 2018.           |            |           |        |           |     |
| [4] S.                                            | Overflow, |                                                            | “Stack overflow |            | developer | survey | 2018      | -   |
| https://insights.stackoverflow.com/survey/2018/,” |           |                                                            |                 |            |           | 2018.  |           |     |
| [5] stackoverflow.blog,                           |           |                                                            | “The            | incredible | growth    |        | of python | -   |
https://stackoverflow.blog/2017/09/06/incredible-growth-python/,”
2018.
| [6] python.org, |     | “python.org | - https://www.python.org,” |     |     | 2018. |     |     |
| --------------- | --- | ----------- | -------------------------- | --- | --- | ----- | --- | --- |
[7] python.org,“Thepythontutorial-https://docs.python.org/3.7/tutorial/,”
2018.
[8] python.org,“Python3.7.1documentation-https://docs.python.org/3.7/,”
2018.
| [9] scipy.org,       | “Scipy  | -           | https://www.scipy.org,”    |                          | 2018. |       |       |     |
| -------------------- | ------- | ----------- | -------------------------- | ------------------------ | ----- | ----- | ----- | --- |
| [10] matplotlib.org, |         | “Matplotlib | - https://matplotlib.org,” |                          |       | 2018. |       |     |
| [11] pandas,         | “pandas | -           | http://pandas.pydata.org,” |                          | 2018. |       |       |     |
| [12] Wingware,       |         | “Wingware   | python ide                 | - https://wingware.com,” |       |       | 2018. |     |
[13] w3schools.com, “Python tutorial - https://www.w3schools.com/python/,”
2018.
[14] Wikipedia,“Debugging-https://en.wikipedia.org/wiki/Debugging,”2018.
| [15] TechBeamers, |     |     | “Get | the | best | python | ide | -   |
| ----------------- | --- | --- | ---- | --- | ---- | ------ | --- | --- |
https://www.techbeamers.com/best-python-ide-python-programming/,”
2018.
| [16] Jupyter,    | “Jupyter | -           | https://jupyter.org,”      |     | 2018. |       |     |     |
| ---------------- | -------- | ----------- | -------------------------- | --- | ----- | ----- | --- | --- |
| [17] JupyterHub, |          | “Jupyterhub | - http://jupyter.org/hub,” |     |       | 2018. |     |     |
134

| [18] python.org,                     | “The        | python                             | standard | library | -   |
| ------------------------------------ | ----------- | ---------------------------------- | -------- | ------- | --- |
| https://docs.python.org/3/library/,” |             | 2018.                              |          |         |     |
| [19] T. P. Guru,                     | “The python | guru - https://thepythonguru.com,” |          | 2018.   |     |
135

Part VII
Solutions to Exercises
136

| Start      | using              | Python   |            |        |
| ---------- | ------------------ | -------- | ---------- | ------ |
| Simulation | and                | Plotting | of Dynamic | System |
| Given the  | autonomous system: |          |            |        |
|            |                    |          | x˙ =ax     | (1)    |
Where:
1
a=−
T
| where T      | is the time constant. |          |     |     |
| ------------ | --------------------- | -------- | --- | --- |
| The solution | for the differential  | equation | is: |     |
x(t)=eatx (2)
0
| Set T=5 | and the initial | condition x(0)=1. |     |     |
| ------- | --------------- | ----------------- | --- | --- |
Create a Script inPython (.py file) where you plot the solution x(t) in the time
interval:
0≤t≤25
| Add Grid,   | and proper Title | and Axis | Labels to the plot. |     |
| ----------- | ---------------- | -------- | ------------------- | --- |
| Python      | Script:          |          |                     |     |
| import math | as mt            |          |                     |     |
1
| import numpy | as np |     |     |     |
| ------------ | ----- | --- | --- | --- |
2
| import matplotlib.pyplot |     | as plt |     |     |
| ------------------------ | --- | ------ | --- | --- |
3
4
5
| 6 # Model | Parameters |     |     |     |
| --------- | ---------- | --- | --- | --- |
7 T = 5
−1/T
8 a =
9
| # Simulation | Parameters |     |     |     |
| ------------ | ---------- | --- | --- | --- |
10
x0 = 1
11
t = 0
12
13
| tstart = | 0   |     |     |     |
| -------- | --- | --- | --- | --- |
14
137

| 15 tstop | = 25 |     |     |     |     |     |
| -------- | ---- | --- | --- | --- | --- | --- |
16
| 17 increment | = 1 |     |     |     |     |     |
| ------------ | --- | --- | --- | --- | --- | --- |
18
x = []
19
x = np.zeros(tstop+1)
20
21
| t = np.arange(tstart |     |     | ,tstop+1,increment) |     |     |     |
| -------------------- | --- | --- | ------------------- | --- | --- | --- |
22
23
24
| 25 # Define | the              | Function |     |     |     |     |
| ----------- | ---------------- | -------- | --- | --- | --- | --- |
| 26 for k    | in range(tstop): |          |     |     |     |     |
|             | mt.exp(a∗t[k])   |          |     | ∗   |     |     |
| 27 x[k]     | =                |          |     | x0  |     |     |
28
29
| # Plot | the Simulation |     | Results |     |     |     |
| ------ | -------------- | --- | ------- | --- | --- | --- |
30
plt.plot(t,x)
31
| plt. title(’Simulation |     |     | of  | Dynamic | System’) |     |
| ---------------------- | --- | --- | --- | ------- | -------- | --- |
32
33 plt.xlabel(’t’)
34 plt.ylabel(’x’)
35 plt.grid()
| 36 plt.axis([0, |     | 25, 0, | 1]) |     |     |     |
| --------------- | --- | ------ | --- | --- | --- | --- |
37 plt.show()
| The simulation |     | gives  | the results | as shown   | in Figure  | 1.     |
| -------------- | --- | ------ | ----------- | ---------- | ---------- | ------ |
|                |     | Figure | 1:          | Simulation | of Dynamic | System |
[End of Exercise]
138

Python Programming
©Hans-Petter Halvorsen
June 12, 2026
ISBN:978-82-691106-4-7
139

Python Programming